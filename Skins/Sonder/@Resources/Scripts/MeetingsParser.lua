local offset = 0
local meetings = {}

local function getVar(name, fallback)
    local v = SKIN:GetVariable(name)
    if v == nil or v == '' then return fallback end
    return v
end

local function numVar(name, fallback)
    local n = tonumber(getVar(name, tostring(fallback)))
    if n == nil then return fallback end
    return n
end

local function setOpt(meter, option, value)
    SKIN:Bang('!SetOption', meter, option, tostring(value or ''))
end

local function showMeter(meter)
    SKIN:Bang('!ShowMeter', meter)
end

local function hideMeter(meter)
    SKIN:Bang('!HideMeter', meter)
end

local function showGroup(group)
    SKIN:Bang('!ShowMeterGroup', group)
end

local function hideGroup(group)
    SKIN:Bang('!HideMeterGroup', group)
end

local function trim(s)
    s = tostring(s or '')
    s = s:gsub('^%s+', '')
    s = s:gsub('%s+$', '')
    return s
end

local function replaceSpecialBytes(s)
    -- Normalizes UTF-8 dash bytes and common mojibake to ASCII-safe text.
    s = s:gsub(string.char(226,128,148), ' - ') -- em dash
    s = s:gsub(string.char(226,128,147), '-')   -- en dash
    s = s:gsub(string.char(194,160), ' ')       -- nbsp
    s = s:gsub(string.char(195,162,226,130,172,226,128,157), ' - ') -- mojibake em dash
    s = s:gsub(string.char(195,162,226,130,172,226,128,156), '-')   -- mojibake en dash
    return s
end

local function htmlDecode(s)
    s = tostring(s or '')
    s = replaceSpecialBytes(s)
    s = s:gsub('&amp;', '&')
    s = s:gsub('&quot;', '"')
    s = s:gsub('&apos;', "'")
    s = s:gsub('&#39;', "'")
    s = s:gsub('&#44;', ',')
    s = s:gsub('&#124;', '|')
    s = s:gsub('&vert;', '|')
    s = s:gsub('&nbsp;', ' ')
    s = s:gsub('&#8211;', '-')
    s = s:gsub('&#8212;', ' - ')
    s = s:gsub('<br%s*/?>', ' / ')
    s = s:gsub('<[^>]+>', '')
    return replaceSpecialBytes(s)
end

local function cleanText(s)
    s = htmlDecode(s)
    s = s:gsub('\r\n', ' ')
    s = s:gsub('\n', ' ')
    s = s:gsub('%s+', ' ')
    s = s:gsub('undefined,%s*', '')
    s = s:gsub(',%s*undefined', '')
    s = s:gsub('%s+%-+%s+undefined', '')
    s = s:gsub('undefined', '')
    return trim(s)
end

local function splitFields(record)
    local fields = {}
    for part in tostring(record or ''):gmatch('([^|]+)') do
        local cleaned = cleanText(part)
        if cleaned ~= '' then
            table.insert(fields, cleaned)
        end
    end
    return fields
end

local function parseTimeRange(timeText)
    local h1, m1, h2, m2 = tostring(timeText or ''):match('(%d%d?):(%d%d).-(%d%d?):(%d%d)')
    if not h1 then
        h1, m1 = tostring(timeText or ''):match('(%d%d?):(%d%d)')
    end

    local startLabel = trim(timeText)
    local startMinutes = nil
    local endMinutes = nil

    if h1 and m1 then
        startMinutes = tonumber(h1) * 60 + tonumber(m1)
        startLabel = string.format('%02d:%02d', tonumber(h1), tonumber(m1))
    end

    if h2 and m2 then
        endMinutes = tonumber(h2) * 60 + tonumber(m2)
    end

    return startLabel, startMinutes, endMinutes
end

local function shortInfo(info)
    info = cleanText(info)
    local beforeDash = info:match('^(.-)%s+%-%s+')
    if beforeDash and beforeDash ~= '' then
        return trim(beforeDash)
    end
    return info
end

local function readRawFeed()
    local measure = SKIN:GetMeasure('MeasureMeetingsRaw')
    if not measure then return '' end
    return measure:GetStringValue() or ''
end

local function buildRecords(raw)
    raw = htmlDecode(raw)
    raw = raw:gsub('\r\n', '\n')
    raw = raw:gsub('\r', '\n')

    local records = {}

    if raw:find('||', 1, true) then
        raw = raw .. '||'
        for record in raw:gmatch('(.-)||') do
            record = trim(record:gsub('^%s*[%*%-]?%s*', ''))
            if record ~= '' then
                table.insert(records, record)
            end
        end
    else
        for record in raw:gmatch('[^\n]+') do
            record = trim(record:gsub('^%s*[%*%-]?%s*', ''))
            if record ~= '' then
                table.insert(records, record)
            end
        end
    end

    return records
end

local function isPastByStart(startMinutes, nowMinutes, tolerance)
    if startMinutes == nil then return false end
    return (startMinutes + tolerance) < nowMinutes
end

local function parseMeetings()
    local raw = readRawFeed()
    local records = buildRecords(raw)

    local now = os.date('*t')
    local nowMinutes = now.hour * 60 + now.min

    local hidePastStarted = numVar('MeetingsHidePastStarted', 1)
    local tolerance = numVar('MeetingsPastToleranceMinutes', 20)
    local maxItems = numVar('MeetingsMaxItems', 15)

    if tolerance < 0 then tolerance = 0 end
    if maxItems < 1 then maxItems = 15 end

    meetings = {}

    for _, record in ipairs(records) do
        local fields = splitFields(record)

        if #fields >= 3 then
            local timeRaw = fields[1]
            local room = fields[2]

            local infoParts = {}
            for i = 3, #fields do
                table.insert(infoParts, fields[i])
            end

            local info = cleanText(table.concat(infoParts, ' | '))
            local startLabel, startMinutes, endMinutes = parseTimeRange(timeRaw)

            local shouldShow = true
            if hidePastStarted == 1 and isPastByStart(startMinutes, nowMinutes, tolerance) then
                shouldShow = false
            end

            if shouldShow then
                table.insert(meetings, {
                    timeRaw = cleanText(timeRaw),
                    startLabel = startLabel,
                    startMinutes = startMinutes,
                    endMinutes = endMinutes,
                    room = cleanText(room),
                    info = info,
                    shortInfo = shortInfo(info)
                })
            end
        end

        if #meetings >= maxItems then
            break
        end
    end
end

local function hideRows()
    for i = 1, 4 do
        hideGroup('Row' .. i)
    end
end

local function lastUpdateText()
    local last = ''
    local m = SKIN:GetMeasure('MeasureLastUpdate')
    if m then last = m:GetStringValue() end
    if last == '' then last = os.date('%H:%M') end
    return last
end

local function render()
    local visibleRows = numVar('MeetingsVisibleRows', 4)
    if visibleRows < 1 then visibleRows = 1 end
    if visibleRows > 4 then visibleRows = 4 end

    local total = #meetings
    local maxOffset = math.max(total - visibleRows, 0)

    if offset > maxOffset then offset = maxOffset end
    if offset < 0 then offset = 0 end

    if total == 0 then
        hideRows()
        showMeter('MeterFallback')
        hideMeter('MeterNavUp')
        hideMeter('MeterNavDown')
        setOpt('MeterFallback', 'Text', getVar('MeetingsFallback', 'Sem reunioes pendentes para hoje.'))
        setOpt('MeterMeetingsStatus', 'Text', 'Atualizado as ' .. lastUpdateText() .. ' - 0/0')
        SKIN:Bang('!UpdateMeterGroup', 'Meetings')
        SKIN:Bang('!Redraw')
        return
    end

    hideMeter('MeterFallback')

    for row = 1, 4 do
        local idx = offset + row
        local meeting = meetings[idx]

        if row <= visibleRows and meeting then
            local tooltip = meeting.timeRaw .. ' - ' .. meeting.room .. '\n' .. meeting.info

            setOpt('MeterM' .. row .. 'Time', 'Text', meeting.startLabel)
            setOpt('MeterM' .. row .. 'Room', 'Text', meeting.room)
            setOpt('MeterM' .. row .. 'Info', 'Text', meeting.shortInfo)

            setOpt('MeterRow' .. row .. 'Bg', 'ToolTipText', tooltip)
            setOpt('MeterM' .. row .. 'Time', 'ToolTipText', tooltip)
            setOpt('MeterM' .. row .. 'Room', 'ToolTipText', tooltip)
            setOpt('MeterM' .. row .. 'Info', 'ToolTipText', tooltip)

            showGroup('Row' .. row)
        else
            hideGroup('Row' .. row)
        end
    end

    local first = offset + 1
    local lastVisible = math.min(offset + visibleRows, total)
    setOpt('MeterMeetingsStatus', 'Text', 'Atualizado as ' .. lastUpdateText() .. ' - ' .. first .. '-' .. lastVisible .. '/' .. total)

    if total > visibleRows then
        showMeter('MeterNavUp')
        showMeter('MeterNavDown')
    else
        hideMeter('MeterNavUp')
        hideMeter('MeterNavDown')
    end

    SKIN:Bang('!UpdateMeterGroup', 'Meetings')
    SKIN:Bang('!Redraw')
end

function Refresh()
    parseMeetings()
    render()
end

function ScrollUp()
    offset = offset - 1
    if offset < 0 then offset = 0 end
    render()
end

function ScrollDown()
    local visibleRows = numVar('MeetingsVisibleRows', 4)
    if visibleRows < 1 then visibleRows = 1 end
    if visibleRows > 4 then visibleRows = 4 end

    local maxOffset = math.max(#meetings - visibleRows, 0)
    offset = offset + 1
    if offset > maxOffset then offset = maxOffset end
    render()
end

function ConnectionError()
    hideRows()
    showMeter('MeterFallback')
    hideMeter('MeterNavUp')
    hideMeter('MeterNavDown')
    setOpt('MeterFallback', 'Text', 'Agenda indisponivel')
    setOpt('MeterMeetingsStatus', 'Text', 'Falha de conexao as ' .. os.date('%H:%M'))
    SKIN:Bang('!UpdateMeterGroup', 'Meetings')
    SKIN:Bang('!Redraw')
end

function Initialize()
    Refresh()
end

function Update()
    Refresh()
    return 0
end
