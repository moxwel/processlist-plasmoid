/*
    Parsers for the commands main.qml runs: top's batch output while the process list is on screen, and the
    first lines of /proc/stat or /proc/meminfo while it is not. They keep no state, so .pragma library shares a
    single copy among every widget instance.
*/

.pragma library

const KIB_PER_MIB = 1024;
const KIB_PER_GIB = 1024 * KIB_PER_MIB;
const KIB_PER_TIB = 1024 * KIB_PER_GIB;

const KIB_PER_SUFFIX = {
    k: 1,
    m: KIB_PER_MIB,
    g: KIB_PER_GIB,
    t: KIB_PER_TIB,
    p: 1024 * KIB_PER_TIB,
    e: 1024 * 1024 * KIB_PER_TIB,
};

const CPU_IDLE_PATTERN = /([\d.]+)\s+id/;
const PROCESS_ROW_PATTERN = /^\s*(\d+)\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+\S+\s+\S+\s+([\d.]+)\s+[\d.]+\s+\S+\s+(.+)$/;
const OWN_TOP_PATTERN = /\btop\b.*-bn2/;
const UPTIME_PATTERN = /^([\d.]+)\s+[\d.]+$/m;

const IDLE_FIELD = 4;
const IOWAIT_FIELD = 5;
const STEAL_FIELD = 8;

function parseKiB(text) {
    const suffix = text.charAt(text.length - 1).toLowerCase();
    const kibPerUnit = KIB_PER_SUFFIX[suffix] || 1;
    return parseFloat(text) * kibPerUnit;
}

function formatKiB(kib) {
    const isGiB = kib >= KIB_PER_GIB;
    if (isGiB) return (kib / KIB_PER_GIB).toFixed(1) + " GiB";
    const isMiB = kib >= KIB_PER_MIB;
    if (isMiB) return (kib / KIB_PER_MIB).toFixed(0) + " MiB";
    return kib.toFixed(0) + " KiB";
}

function readCpuSummary(line) {
    const idleMatch = line.match(CPU_IDLE_PATTERN);
    const usagePercent = idleMatch ? 100 - parseFloat(idleMatch[1]) : 0;
    return { usagePercent: usagePercent, memoryText: "" };
}

function readMemorySummary(output) {
    const memInfo = parseMemInfo(output);
    const hasMemInfo = memInfo !== null;
    const usagePercent = hasMemInfo ? memInfo.usagePercent : 0;
    const memoryText = hasMemInfo ? memInfo.memoryText : "";
    return { usagePercent: usagePercent, memoryText: memoryText };
}

function readProcesses(lines, isCpu, limit) {
    const processes = [];
    for (let i = 0; i < lines.length && processes.length < limit; i++) {
        const rowMatch = lines[i].match(PROCESS_ROW_PATTERN);
        if (!rowMatch) continue;
        const command = rowMatch[4].trim();
        const isOwnTop = OWN_TOP_PATTERN.test(command);
        if (isOwnTop) continue;
        const executable = command.split(" ")[0];
        const isPath = executable.charAt(0) === "/";
        const name = isPath ? executable.substring(executable.lastIndexOf("/") + 1) : executable;
        const usageText = isCpu ? parseFloat(rowMatch[3]).toFixed(1) + "%" : formatKiB(parseKiB(rowMatch[2]));
        processes.push({ pid: rowMatch[1], name: name, command: command, usageText: usageText });
    }
    return processes;
}

function parseTopOutput(output, isCpu, limit) {
    const allLines = output.split("\n");
    let lastIterationStart = 0;
    for (let i = 0; i < allLines.length; i++) {
        const isCpuLine = allLines[i].indexOf("%Cpu") === 0;
        if (isCpuLine) lastIterationStart = i;
    }
    const lines = allLines.slice(lastIterationStart);
    const summary = isCpu ? readCpuSummary(lines[0]) : readMemorySummary(output);
    const processes = readProcesses(lines, isCpu, limit);
    const uptimeMatch = output.match(UPTIME_PATTERN);
    const uptimeSec = uptimeMatch ? parseFloat(uptimeMatch[1]) : 0;
    return {
        usagePercent: summary.usagePercent,
        memoryText: summary.memoryText,
        processes: processes,
        uptimeSec: uptimeSec,
    };
}

function parseCpuJiffies(output) {
    const fields = output.trim().split(/\s+/);
    const timeFields = fields.slice(1, STEAL_FIELD + 1);
    let total = 0;
    for (const field of timeFields) total += parseFloat(field);
    const idle = parseFloat(fields[IDLE_FIELD]) + parseFloat(fields[IOWAIT_FIELD]);
    return { total: total, idle: idle };
}

function parseMemInfo(output) {
    const totalMatch = output.match(/MemTotal:\s*(\d+)/);
    const availableMatch = output.match(/MemAvailable:\s*(\d+)/);
    const hasBothLines = totalMatch !== null && availableMatch !== null;
    if (!hasBothLines) return null;
    const totalKiB = parseFloat(totalMatch[1]);
    const usedKiB = totalKiB - parseFloat(availableMatch[1]);
    return { usagePercent: usedKiB / totalKiB * 100, memoryText: formatKiB(usedKiB) + " / " + formatKiB(totalKiB) };
}
