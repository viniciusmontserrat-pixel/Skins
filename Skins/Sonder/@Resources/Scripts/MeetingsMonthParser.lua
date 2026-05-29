-- Sonder / Le.IA Agenda - Monthly Meetings Panel
-- Rainmeter Lua 5.1-compatible script.

local events = {}
local eventsByDate = {}
local selectedDateKey = nil
local selectedEventIndex = nil

local monthNames = {'Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'}
local monthShort = {'Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'}

local layout = {
    canvasW = 1460,
    canvasH = 760,
    gridX = 360,
    gridY = 112,
    gridW = 1065,
    headerH = 48,
    cellW = 1065 / 7,
    cellH = 91,
    eventLeftPad = 8,
    eventRightPad = 8,
    eventTopPad = 26,
    dayPad = 9
}

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

local function intVar(name, fallback)
    local n = math.floor(numVar(name, fallback))
    return n
end

local function scale()
    local s = numVar('Scale', 1.0)
    if s < 0.45 then s = 0.45 end
    if s > 2.00 then s = 2.00 end
    return s
end

local function px(v)
    return math.floor((v * scale()) + 0.5)
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

local function updateMeter(meter)
    SKIN:Bang('!UpdateMeter', meter)
end

local function updateGroup(group)
    SKIN:Bang('!UpdateMeterGroup', group)
end

local function redraw()
    SKIN:Bang('!Redraw')
end

local function configFile()
    return getVar('CURRENTPATH', '') .. 'Meetings Month.ini'
end

local function writeVar(name, value)
    SKIN:Bang('!SetVariable', name, tostring(value or ''))
    SKIN:Bang('!WriteKeyValue', 'Variables', name, tostring(value or ''), configFile())
end

local function trim(s)
    s = tostring(s or '')
    s = s:gsub('^%s+', '')
    s = s:gsub('%s+$', '')
    return s
end

local function safeText(s)
    s = tostring(s or '')
    s = s:gsub('[\r\n]+', ' ')
    s = s:gsub('%s+', ' ')
    s = s:gsub('%[', '('):gsub('%]', ')')
    s = s:gsub('#', 'nº')
    return trim(s)
end

local function htmlDecode(s)
    s = tostring(s or '')
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
    return s
end

local function normalizeKey(s)
    s = tostring(s or ''):lower()
    s = htmlDecode(s)
    local repl = {
        ['á']='a',['à']='a',['ã']='a',['â']='a',['ä']='a',
        ['é']='e',['è']='e',['ê']='e',['ë']='e',
        ['í']='i',['ì']='i',['î']='i',['ï']='i',
        ['ó']='o',['ò']='o',['õ']='o',['ô']='o',['ö']='o',
        ['ú']='u',['ù']='u',['û']='u',['ü']='u',
        ['ç']='c',
        ['Á']='a',['À']='a',['Ã']='a',['Â']='a',['Ä']='a',
        ['É']='e',['È']='e',['Ê']='e',['Ë']='e',
        ['Í']='i',['Ì']='i',['Î']='i',['Ï']='i',
        ['Ó']='o',['Ò']='o',['Õ']='o',['Ô']='o',['Ö']='o',
        ['Ú']='u',['Ù']='u',['Û']='u',['Ü']='u',
        ['Ç']='c'
    }
    for a,b in pairs(repl) do s = s:gsub(a,b) end
    s = s:gsub('[%p%c]', ' ')
    s = s:gsub('%s+', ' ')
    return trim(s)
end

local function varColor(name, fallback)
    return getVar(name, fallback)
end

local function categoryColor(city, room, link)
    local key = normalizeKey((city or '') .. ' ' .. (room or '') .. ' ' .. (link or ''))

    if key:find('virtual', 1, true) or key:find('online', 1, true) or key:find('zoom', 1, true) or key:find('teams', 1, true) or key:find('meet', 1, true) or key:find('video', 1, true) then
        return varColor('ColorVirtual', '116,116,116'), 'Virtual'
    end

    if key:find('ribeirao', 1, true) or key:find('ribeir', 1, true) then
        return varColor('ColorRibeiraoReunioes', '18,145,158'), 'Ribeirão · Reuniões'
    end

    if key:find('podcast', 1, true) then
        return varColor('ColorLocalPodcast', '116,95,210'), 'Local - Podcast'
    end

    if key:find('fundos', 1, true) then
        return varColor('ColorLocalFundos', '54,145,95'), 'Local - Fundos'
    end

    if key:find('fabio', 1, true) or key:find('dr fabio', 1, true) or key:find('doutor fabio', 1, true) then
        return varColor('ColorLocalFabio', '218,130,54'), 'Local - Dr. Fabio'
    end

    if key:find('redonda', 1, true) then
        return varColor('ColorLocalRedonda', '202,70,94'), 'Local - Redonda'
    end

    if key:find('reunioes', 1, true) or key:find('reuniao', 1, true) or key:find('reuniões', 1, true) or key:find('reunião', 1, true) then
        return varColor('ColorLocalReunioes', '42,112,214'), 'Local - Reunioes'
    end

    return varColor('ColorUnknown', '72,72,72'), 'Não classificado'
end

local function daysInMonth(year, month)
    return tonumber(os.date('%d', os.time({year=year, month=month+1, day=0, hour=12})))
end

local function mondayWeekday(year, month, day)
    local w = tonumber(os.date('%w', os.time({year=year, month=month, day=day, hour=12}))) -- Sunday=0
    if w == 0 then return 7 end
    return w
end

local function dateKey(year, month, day)
    local t = os.date('*t', os.time({year=year, month=month, day=day, hour=12}))
    return string.format('%04d%02d%02d', t.year, t.month, t.day), t
end

local function dateHumanFromKey(key)
    key = tostring(key or '')
    local y,m,d = key:match('^(%d%d%d%d)(%d%d)(%d%d)$')
    if not y then return '' end
    return string.format('%s/%s/%s', d, m, y)
end

local function currentMonthState()
    local year = intVar('MonthYear', 0)
    local month = intVar('MonthNumber', 0)
    if year < 1900 or month < 1 or month > 12 then
        local now = os.date('*t')
        year = now.year
        month = now.month
    end
    return year, month
end

local function monthBounds(year, month)
    local startDate = string.format('%04d-%02d-01', year, month)
    local lastDay = daysInMonth(year, month)
    local endDate = string.format('%04d-%02d-%02d', year, month, lastDay)
    local key = string.format('%04d-%02d', year, month)
    return key, startDate, endDate
end

local function setMonthState(year, month, persist)
    while month < 1 do
        month = month + 12
        year = year - 1
    end
    while month > 12 do
        month = month - 12
        year = year + 1
    end

    local key, startDate, endDate = monthBounds(year, month)

    if persist then
        writeVar('MonthYear', year)
        writeVar('MonthNumber', month)
        writeVar('MonthKey', key)
        writeVar('MonthStart', startDate)
        writeVar('MonthEnd', endDate)
    else
        SKIN:Bang('!SetVariable', 'MonthYear', tostring(year))
        SKIN:Bang('!SetVariable', 'MonthNumber', tostring(month))
        SKIN:Bang('!SetVariable', 'MonthKey', key)
        SKIN:Bang('!SetVariable', 'MonthStart', startDate)
        SKIN:Bang('!SetVariable', 'MonthEnd', endDate)
    end

    selectedEventIndex = nil
    local today = os.date('*t')
    if today.year == year and today.month == month then
        selectedDateKey = string.format('%04d%02d%02d', year, month, today.day)
    else
        selectedDateKey = string.format('%04d%02d01', year, month)
    end
end

local function setMonthTitle()
    local year, month = currentMonthState()
    setOpt('MeterCurrentMonthText', 'Text', string.upper(monthNames[month] .. ' ' .. tostring(year)))
    updateMeter('MeterCurrentMonthText')

    local baseX = 812
    local y = 38
    local w = 40
    local gap = 8
    for i=1,12 do
        local x = baseX + (i-1) * (w + gap)
        local bg = string.format('MeterMonth%02dBg', i)
        local tx = string.format('MeterMonth%02dText', i)
        setOpt(bg, 'X', px(x))
        setOpt(bg, 'Y', px(y))
        setOpt(bg, 'Shape', 'Rectangle 0,0,' .. px(w) .. ',' .. px(24) .. ',' .. px(10) .. ' | Fill Color ' .. (i == month and '20,20,20,235' or '255,255,255,90') .. ' | StrokeWidth 0')
        setOpt(tx, 'X', px(x))
        setOpt(tx, 'Y', px(y))
        setOpt(tx, 'W', px(w))
        setOpt(tx, 'H', px(24))
        setOpt(tx, 'FontColor', i == month and '255,255,255,250' or getVar('TextDark','20,20,20') .. ',245')
        showMeter(bg)
        showMeter(tx)
    end
    updateGroup('MonthPills')
end

local function readRawFeed()
    local measure = SKIN:GetMeasure('MeasureMeetingsMonthRaw')
    if not measure then return '' end
    return measure:GetStringValue() or ''
end

local function splitRecords(raw)
    raw = htmlDecode(raw)
    raw = raw:gsub('\r\n', '\n'):gsub('\r', '\n')
    local records = {}

    if raw:find('||', 1, true) then
        raw = raw .. '||'
        for record in raw:gmatch('(.-)||') do
            record = trim(record:gsub('^%s*[%*%-]?%s*', ''))
            if record ~= '' then table.insert(records, record) end
        end
    else
        for record in raw:gmatch('[^\n]+') do
            record = trim(record:gsub('^%s*[%*%-]?%s*', ''))
            if record ~= '' then table.insert(records, record) end
        end
    end
    return records
end

local function splitFields(record)
    local fields = {}
    record = tostring(record or '') .. '|'
    for part in record:gmatch('(.-)|') do
        table.insert(fields, safeText(htmlDecode(part)))
        if #fields > 20 then break end
    end
    while #fields > 0 and fields[#fields] == '' do table.remove(fields) end
    return fields
end

local function jsonUnescape(s)
    s = tostring(s or '')
    s = s:gsub('\\/', '/')
    s = s:gsub('\\n', ' '):gsub('\\r', ' '):gsub('\\t', ' ')
    s = s:gsub('\\"', '"')
    s = s:gsub('\\u00e1', 'á'):gsub('\\u00e0', 'à'):gsub('\\u00e3', 'ã'):gsub('\\u00e2', 'â')
    s = s:gsub('\\u00e9', 'é'):gsub('\\u00ea', 'ê')
    s = s:gsub('\\u00ed', 'í')
    s = s:gsub('\\u00f3', 'ó'):gsub('\\u00f4', 'ô'):gsub('\\u00f5', 'õ')
    s = s:gsub('\\u00fa', 'ú')
    s = s:gsub('\\u00e7', 'ç')
    s = s:gsub('\\u00c1', 'Á'):gsub('\\u00c0', 'À'):gsub('\\u00c3', 'Ã'):gsub('\\u00c2', 'Â')
    s = s:gsub('\\u00c9', 'É'):gsub('\\u00ca', 'Ê')
    s = s:gsub('\\u00cd', 'Í')
    s = s:gsub('\\u00d3', 'Ó'):gsub('\\u00d4', 'Ô'):gsub('\\u00d5', 'Õ')
    s = s:gsub('\\u00da', 'Ú')
    s = s:gsub('\\u00c7', 'Ç')
    return safeText(s)
end

local function jsonValue(obj, keys)
    for _,key in ipairs(keys) do
        local patt = '"' .. key .. '"%s*:%s*"(.-)"'
        local v = obj:match(patt)
        if v ~= nil then return jsonUnescape(v) end
        patt = '"' .. key .. '"%s*:%s*([^,%}%]]+)'
        v = obj:match(patt)
        if v ~= nil then
            v = v:gsub('"','')
            if v ~= 'null' and v ~= 'undefined' then return safeText(v) end
        end
    end
    return ''
end

local function parseDate(s)
    s = tostring(s or '')
    local y,m,d = s:match('(%d%d%d%d)%-(%d%d)%-(%d%d)')
    if y then return tonumber(y), tonumber(m), tonumber(d) end
    d,m,y = s:match('(%d%d?)/(%d%d?)/(%d%d%d%d)')
    if y then return tonumber(y), tonumber(m), tonumber(d) end
    d,m,y = s:match('(%d%d?)%-(%d%d?)%-(%d%d%d%d)')
    if y then return tonumber(y), tonumber(m), tonumber(d) end
    return nil, nil, nil
end

local function parseTime(s)
    local h, m = tostring(s or ''):match('(%d%d?):(%d%d)')
    if not h then return '', nil end
    local minutes = tonumber(h) * 60 + tonumber(m)
    return string.format('%02d:%02d', tonumber(h), tonumber(m)), minutes
end

local function parseTimeRange(text, startText, endText)
    text = tostring(text or '')
    local h1,m1,h2,m2 = text:match('(%d%d?):(%d%d).-(%d%d?):(%d%d)')
    if h1 and m1 then
        local startLabel = string.format('%02d:%02d', tonumber(h1), tonumber(m1))
        local endLabel = h2 and string.format('%02d:%02d', tonumber(h2), tonumber(m2)) or ''
        local startMinutes = tonumber(h1) * 60 + tonumber(m1)
        local endMinutes = h2 and (tonumber(h2) * 60 + tonumber(m2)) or nil
        return endLabel ~= '' and (startLabel .. '-' .. endLabel) or startLabel, startMinutes, endMinutes
    end

    local sl, sm = parseTime(startText or text)
    local el, em = parseTime(endText or '')
    if sl ~= '' and el ~= '' then return sl .. '-' .. el, sm, em end
    if sl ~= '' then return sl, sm, nil end
    return safeText(text), nil, nil
end

local function inferCity(room, city)
    city = safeText(city)
    if city ~= '' then return city end
    local key = normalizeKey(room)
    if key:find('ribeir', 1, true) then return 'Ribeirão' end
    if key:find('virtual', 1, true) or key:find('online', 1, true) or key:find('zoom', 1, true) or key:find('teams', 1, true) or key:find('meet', 1, true) then return 'Virtual' end
    return 'Local'
end

local function makeEvent(t)
    local y,m,d = parseDate(t.date or t.start or '')
    if not y then return nil end

    local key, normalizedDate = dateKey(y, m, d)
    local timeRange, startMinutes, endMinutes = parseTimeRange(t.time or '', t.start or '', t.finish or t['end'] or '')
    local city = inferCity(t.room or t.location or '', t.city or '')
    local room = safeText(t.room or t.location or '')
    local title = safeText(t.title or t.subject or t.summary or '')
    local participants = safeText(t.participants or t.attendees or '')
    local responsible = safeText(t.responsible or t.organizer or t.host or '')
    local status = safeText(t.status or '')
    local link = safeText(t.link or t.url or '')
    local notes = safeText(t.notes or t.description or '')

    if room == '' and link ~= '' then room = 'Virtual' end
    if title == '' then title = 'Reunião' end

    local color, category = categoryColor(city, room, link)

    return {
        dateKey = key,
        dateSort = tonumber(key),
        year = normalizedDate.year,
        month = normalizedDate.month,
        day = normalizedDate.day,
        dateHuman = string.format('%02d/%02d/%04d', normalizedDate.day, normalizedDate.month, normalizedDate.year),
        timeRange = timeRange,
        startMinutes = startMinutes or 9999,
        endMinutes = endMinutes,
        city = city,
        room = room,
        title = title,
        participants = participants,
        responsible = responsible,
        status = status,
        link = link,
        notes = notes,
        color = color,
        category = category
    }
end

local function eventFromPipe(record)
    local f = splitFields(record)
    if #f < 3 then return nil end

    if #f >= 10 then
        return makeEvent({date=f[1], time=f[2], city=f[3], room=f[4], title=f[5], participants=f[6], responsible=f[7], status=f[8], link=f[9], notes=f[10]})
    elseif #f >= 6 then
        return makeEvent({date=f[1], time=f[2], city=f[3], room=f[4], title=f[5], participants=f[6], responsible=f[7], status=f[8], link=f[9], notes=f[10]})
    elseif #f >= 4 then
        return makeEvent({date=f[1], time=f[2], room=f[3], title=f[4], participants=f[5], notes=f[6]})
    else
        return nil
    end
end

local function jsonObjects(raw)
    local objects = {}
    raw = tostring(raw or '')
    for obj in raw:gmatch('%b{}') do
        table.insert(objects, obj)
    end
    return objects
end

local function eventFromJsonObject(obj)
    local start = jsonValue(obj, {'start','startAt','start_time','inicio','dataHoraInicio','starts_at'})
    local finish = jsonValue(obj, {'end','finish','endAt','end_time','fim','dataHoraFim','ends_at'})
    local date = jsonValue(obj, {'date','data','day','dia'})
    if date == '' then date = start end

    return makeEvent({
        date = date,
        start = start,
        finish = finish,
        time = jsonValue(obj, {'time','hora','horario','period'}),
        city = jsonValue(obj, {'city','cidade','unidade'}),
        room = jsonValue(obj, {'room','sala','location','local','place'}),
        title = jsonValue(obj, {'title','titulo','summary','assunto','subject','name'}),
        participants = jsonValue(obj, {'participants','participantes','attendees','convidados','pessoas'}),
        responsible = jsonValue(obj, {'responsible','responsavel','organizer','host','owner'}),
        status = jsonValue(obj, {'status'}),
        link = jsonValue(obj, {'link','url','meet','meetLink','meeting_url'}),
        notes = jsonValue(obj, {'notes','observacoes','description','descricao','body'})
    })
end

local function parseFeed()
    local raw = readRawFeed()
    raw = htmlDecode(raw)
    events = {}
    eventsByDate = {}

    local year, month = currentMonthState()

    if trim(raw) == '' then return end

    local parsedAny = false
    if raw:find('{', 1, true) and raw:find('}', 1, true) then
        for _, obj in ipairs(jsonObjects(raw)) do
            local ev = eventFromJsonObject(obj)
            if ev and ev.year == year and ev.month == month then
                table.insert(events, ev)
                parsedAny = true
            end
        end
    end

    if not parsedAny then
        for _, record in ipairs(splitRecords(raw)) do
            local ev = eventFromPipe(record)
            if ev and ev.year == year and ev.month == month then
                table.insert(events, ev)
            end
        end
    end

    table.sort(events, function(a,b)
        if a.dateSort ~= b.dateSort then return a.dateSort < b.dateSort end
        if a.startMinutes ~= b.startMinutes then return a.startMinutes < b.startMinutes end
        return (a.title or '') < (b.title or '')
    end)

    for idx, ev in ipairs(events) do
        ev.index = idx
        if not eventsByDate[ev.dateKey] then eventsByDate[ev.dateKey] = {} end
        table.insert(eventsByDate[ev.dateKey], ev)
    end
end

local function lastUpdateText()
    local m = SKIN:GetMeasure('MeasureLastUpdate')
    local last = m and m:GetStringValue() or ''
    if last == '' then last = os.date('%H:%M') end
    return last
end

local function meetingTooltip(ev)
    if not ev then return '' end
    local parts = {
        'Data: ' .. (ev.dateHuman or ''),
        'Horário: ' .. (ev.timeRange or ''),
        'Cidade: ' .. (ev.city or ''),
        'Sala: ' .. (ev.room or ''),
        'Reunião: ' .. (ev.title or ''),
        'Participantes: ' .. (ev.participants or ''),
        'Responsável: ' .. (ev.responsible or ''),
        'Status: ' .. (ev.status or ''),
        'Link: ' .. (ev.link or ''),
        'Observações: ' .. (ev.notes or '')
    }
    return safeText(table.concat(parts, ' | '))
end

local function compactRoom(room)
    room = safeText(room)
    room = room:gsub('Sala de ', ''):gsub('Sala dos ', ''):gsub('Sala do ', ''):gsub('Sala ', '')
    room = room:gsub('Reuniões', 'Reun.'):gsub('Reunião', 'Reun.')
    return room
end

local function eventCompact(ev)
    local room = compactRoom(ev.room)
    local title = safeText(ev.title)
    local time = safeText(ev.timeRange)
    local startOnly = time:match('^(%d%d:%d%d)') or time
    local txt = startOnly
    if room ~= '' then txt = txt .. ' · ' .. room end
    if title ~= '' then txt = txt .. ' · ' .. title end
    return txt
end

local function hideAllEventSlots()
    hideGroup('Events')
end

local function setStatus(text)
    setOpt('MeterSyncStatus', 'Text', safeText(text))
    updateMeter('MeterSyncStatus')
end

local function renderDetails()
    hideGroup('Details')

    local maxRows = intVar('DayDetailsMaxItems', 12)
    if maxRows < 1 then maxRows = 1 end
    if maxRows > 12 then maxRows = 12 end

    if selectedEventIndex and events[selectedEventIndex] then
        local ev = events[selectedEventIndex]
        setOpt('MeterDetailsTitle', 'Text', 'DETALHE DA REUNIÃO')
        setOpt('MeterDetailsSub', 'Text', safeText((ev.dateHuman or '') .. ' · ' .. (ev.timeRange or '')))

        local rows = {
            {'Cidade', ev.city},
            {'Sala', ev.room},
            {'Categoria', ev.category},
            {'Reunião', ev.title},
            {'Participantes', ev.participants},
            {'Responsável', ev.responsible},
            {'Status', ev.status},
            {'Link', ev.link},
            {'Observações', ev.notes}
        }

        local r = 1
        for _, row in ipairs(rows) do
            local value = safeText(row[2] or '')
            if value ~= '' and r <= maxRows then
                local meter = string.format('MeterDetail%02d', r)
                setOpt(meter, 'Text', safeText(row[1] .. ': ' .. value))
                setOpt(meter, 'ToolTipText', safeText(row[1] .. ': ' .. value))
                showMeter(meter)
                r = r + 1
            end
        end
        setOpt('MeterDetailsFooter', 'Text', 'Ficha completa da reunião selecionada.')
        updateGroup('Details')
        updateMeter('MeterDetailsTitle')
        updateMeter('MeterDetailsSub')
        updateMeter('MeterDetailsFooter')
        return
    end

    local key = selectedDateKey
    local list = key and eventsByDate[key] or nil
    setOpt('MeterDetailsTitle', 'Text', 'DETALHES DO DIA')
    setOpt('MeterDetailsSub', 'Text', key and dateHumanFromKey(key) or 'Selecione uma data no calendário')

    if not list or #list == 0 then
        setOpt('MeterDetail01', 'Text', getVar('MeetingsMonthFallback', 'Sem reuniões para o período selecionado.'))
        setOpt('MeterDetail01', 'ToolTipText', getVar('MeetingsMonthFallback', 'Sem reuniões para o período selecionado.'))
        showMeter('MeterDetail01')
        setOpt('MeterDetailsFooter', 'Text', 'Nenhum item vinculado à data selecionada.')
    else
        local shown = math.min(#list, maxRows)
        for i=1, shown do
            local ev = list[i]
            local meter = string.format('MeterDetail%02d', i)
            local text = safeText((ev.timeRange or '') .. ' | ' .. (ev.room or '') .. ' | ' .. (ev.title or '') .. (ev.participants ~= '' and (' | ' .. ev.participants) or ''))
            setOpt(meter, 'Text', text)
            setOpt(meter, 'ToolTipText', meetingTooltip(ev))
            setOpt(meter, 'LeftMouseUpAction', '[!CommandMeasure MeasureMeetingsMonthScript "SelectEvent(' .. tostring(ev.index) .. ')"]')
            showMeter(meter)
        end
        if #list > shown then
            setOpt('MeterDetailsFooter', 'Text', '+' .. tostring(#list - shown) .. ' reuniões além do limite visual do painel.')
        else
            setOpt('MeterDetailsFooter', 'Text', 'Clique em uma reunião para ver a ficha completa.')
        end
    end

    updateGroup('Details')
    updateMeter('MeterDetailsTitle')
    updateMeter('MeterDetailsSub')
    updateMeter('MeterDetailsFooter')
end

local function renderCalendar()
    setMonthTitle()
    hideAllEventSlots()

    local year, month = currentMonthState()
    local firstW = mondayWeekday(year, month, 1)
    local startDay = 1 - (firstW - 1)
    local today = os.date('*t')
    local todayKey = string.format('%04d%02d%02d', today.year, today.month, today.day)

    local slots = intVar('CellEventSlots', 5)
    if slots < 1 then slots = 1 end
    if slots > 6 then slots = 6 end

    local cellW = layout.cellW
    local cellH = layout.cellH
    local eventXPad = layout.eventLeftPad
    local eventW = cellW - layout.eventLeftPad - layout.eventRightPad
    local eventY0 = layout.eventTopPad
    local gap = 3
    local eventH = math.floor((cellH - eventY0 - 8 - ((slots - 1) * gap)) / slots)
    if eventH < 10 then eventH = 10 end
    if eventH > 16 then eventH = 16 end

    local gridHeight = layout.headerH + 6 * cellH
    setOpt('MeterGridBack', 'Shape', 'Rectangle 0,0,' .. px(layout.gridW) .. ',' .. px(gridHeight) .. ',0 | Fill Color 255,255,255,10 | Stroke Color ' .. getVar('LineColor','24,24,24') .. ',210 | StrokeWidth ' .. math.max(1,px(1)))
    updateMeter('MeterGridBack')

    for i=1,42 do
        local dayOffset = startDay + (i - 1)
        local key, dt = dateKey(year, month, dayOffset)
        local col = (i - 1) % 7
        local row = math.floor((i - 1) / 7)
        local x = layout.gridX + col * cellW
        local y = layout.gridY + layout.headerH + row * cellH
        local inMonth = dt.month == month
        local isToday = key == todayKey
        local isSelected = key == selectedDateKey

        local fill = '255,255,255,14'
        local stroke = getVar('LineColor','24,24,24') .. ',150'
        local sw = math.max(1, px(1))
        if inMonth then fill = '255,255,255,22' end
        if isToday then fill = '255,255,255,65' end
        if isSelected then fill = '235,235,226,145'; stroke = getVar('LineColor','24,24,24') .. ',245'; sw = math.max(2, px(2)) end

        local bg = string.format('MeterDay%02dBg', i)
        local num = string.format('MeterDay%02dNumber', i)
        setOpt(bg, 'X', px(x))
        setOpt(bg, 'Y', px(y))
        setOpt(bg, 'Shape', 'Rectangle 0,0,' .. px(cellW) .. ',' .. px(cellH) .. ',0 | Fill Color ' .. fill .. ' | Stroke Color ' .. stroke .. ' | StrokeWidth ' .. sw)
        setOpt(bg, 'ToolTipText', dateHumanFromKey(key))
        setOpt(bg, 'LeftMouseUpAction', '[!CommandMeasure MeasureMeetingsMonthScript "SelectDate(' .. key .. ')"]')
        showMeter(bg)

        setOpt(num, 'X', px(x + cellW - layout.dayPad))
        setOpt(num, 'Y', px(y + 6))
        setOpt(num, 'Text', tostring(dt.day))
        setOpt(num, 'FontColor', inMonth and (getVar('TextDark','20,20,20') .. ',235') or (getVar('TextMuted','90,90,90') .. ',110'))
        setOpt(num, 'LeftMouseUpAction', '[!CommandMeasure MeasureMeetingsMonthScript "SelectDate(' .. key .. ')"]')
        showMeter(num)

        local list = eventsByDate[key] or {}
        local visible = math.min(#list, slots)
        for s=1,visible do
            local bgm = string.format('MeterD%02dE%02dBg', i, s)
            local txm = string.format('MeterD%02dE%02dText', i, s)
            local ex = x + eventXPad
            local ey = y + eventY0 + (s-1) * (eventH + gap)
            local ew = eventW
            local eh = eventH

            if #list > slots and s == slots then
                local remaining = #list - slots + 1
                setOpt(bgm, 'X', px(ex))
                setOpt(bgm, 'Y', px(ey))
                setOpt(bgm, 'Shape', 'Rectangle 0,0,' .. px(ew) .. ',' .. px(eh) .. ',' .. px(4) .. ' | Fill Color ' .. getVar('TextDark','20,20,20') .. ',185 | StrokeWidth 0')
                setOpt(bgm, 'LeftMouseUpAction', '[!CommandMeasure MeasureMeetingsMonthScript "SelectDate(' .. key .. ')"]')
                setOpt(txm, 'X', px(ex + 5))
                setOpt(txm, 'Y', px(ey + 1))
                setOpt(txm, 'W', px(ew - 10))
                setOpt(txm, 'H', px(eh))
                setOpt(txm, 'Text', '+' .. tostring(remaining) .. ' reuniões')
                setOpt(txm, 'ToolTipText', 'Clique para listar todas as reuniões do dia no painel de detalhes.')
                setOpt(txm, 'LeftMouseUpAction', '[!CommandMeasure MeasureMeetingsMonthScript "SelectDate(' .. key .. ')"]')
                showMeter(bgm)
                showMeter(txm)
            else
                local ev = list[s]
                setOpt(bgm, 'X', px(ex))
                setOpt(bgm, 'Y', px(ey))
                setOpt(bgm, 'Shape', 'Rectangle 0,0,' .. px(ew) .. ',' .. px(eh) .. ',' .. px(4) .. ' | Fill Color ' .. (ev.color or getVar('ColorUnknown','72,72,72')) .. ',225 | StrokeWidth 0')
                setOpt(bgm, 'ToolTipText', meetingTooltip(ev))
                setOpt(bgm, 'LeftMouseUpAction', '[!CommandMeasure MeasureMeetingsMonthScript "SelectEvent(' .. tostring(ev.index) .. ')"]')
                setOpt(txm, 'X', px(ex + 5))
                setOpt(txm, 'Y', px(ey + 1))
                setOpt(txm, 'W', px(ew - 10))
                setOpt(txm, 'H', px(eh))
                setOpt(txm, 'Text', eventCompact(ev))
                setOpt(txm, 'ToolTipText', meetingTooltip(ev))
                setOpt(txm, 'LeftMouseUpAction', '[!CommandMeasure MeasureMeetingsMonthScript "SelectEvent(' .. tostring(ev.index) .. ')"]')
                showMeter(bgm)
                showMeter(txm)
            end
        end
    end

    updateGroup('Days')
    updateGroup('Events')
    renderDetails()

    local count = #events
    local countLabel = tostring(count) .. (count == 1 and ' reunião' or ' reuniões')
    setStatus('Atualizado às ' .. lastUpdateText() .. ' · ' .. countLabel .. ' no mês')
    redraw()
end

local function requestMonth()
    local year, month = currentMonthState()
    local key, startDate, endDate = monthBounds(year, month)
    SKIN:Bang('!SetVariable', 'MonthKey', key)
    SKIN:Bang('!SetVariable', 'MonthStart', startDate)
    SKIN:Bang('!SetVariable', 'MonthEnd', endDate)

    local endpoint = getVar('MeetingsMonthEndpoint', '')
    local sep = endpoint:find('?', 1, true) and '&' or '?'
    local tz = getVar('MonthTimezone','-03:00')
    local limit = getVar('MeetingsMonthLimit','250')
    local url = endpoint .. sep .. 'from=' .. startDate .. 'T00:00:00' .. tz .. '&to=' .. endDate .. 'T23:59:59' .. tz .. '&month=' .. key .. '&limit=' .. limit .. '&format=pipe'

    setOpt('MeasureMeetingsMonthFeed', 'URL', url)
    setStatus('Carregando agenda de ' .. monthNames[month] .. ' de ' .. tostring(year) .. '...')
    SKIN:Bang('!UpdateMeasure', 'MeasureMeetingsMonthFeed')
end

function Initialize()
    local year, month = currentMonthState()
    setMonthState(year, month, false)
    setMonthTitle()
    renderDetails()
    requestMonth()
end

function Refresh()
    parseFeed()
    renderCalendar()
end

function ConnectionError()
    setStatus('Falha de conexão com a agenda mensal. Verifique endpoint, TLS e n8n.')
    setOpt('MeterDetailsTitle', 'Text', 'FALHA DE SINCRONIZAÇÃO')
    setOpt('MeterDetailsSub', 'Text', 'Não foi possível consultar o endpoint mensal.')
    hideGroup('Details')
    setOpt('MeterDetail01', 'Text', safeText('Endpoint: ' .. getVar('MeetingsMonthEndpoint','')))
    setOpt('MeterDetail01', 'ToolTipText', safeText(getVar('MeetingsMonthEndpoint','')))
    showMeter('MeterDetail01')
    updateGroup('Details')
    redraw()
end

function PrevMonth()
    local year, month = currentMonthState()
    setMonthState(year, month - 1, true)
    events = {}
    eventsByDate = {}
    selectedEventIndex = nil
    renderCalendar()
    requestMonth()
end

function NextMonth()
    local year, month = currentMonthState()
    setMonthState(year, month + 1, true)
    events = {}
    eventsByDate = {}
    selectedEventIndex = nil
    renderCalendar()
    requestMonth()
end

function SetMonth(m)
    m = tonumber(m)
    if not m or m < 1 or m > 12 then return end
    local year, _ = currentMonthState()
    setMonthState(year, m, true)
    events = {}
    eventsByDate = {}
    selectedEventIndex = nil
    renderCalendar()
    requestMonth()
end

function SelectDate(key)
    key = tostring(key or '')
    if key:match('^%d%d%d%d%d%d%d%d$') then
        selectedDateKey = key
        selectedEventIndex = nil
        renderCalendar()
    end
end

function SelectEvent(idx)
    idx = tonumber(idx)
    if idx and events[idx] then
        selectedEventIndex = idx
        selectedDateKey = events[idx].dateKey
        renderCalendar()
    end
end

function ZoomIn()
    local s = scale() + numVar('ScrollMouseIncrement', 0.05)
    if s > 2.00 then s = 2.00 end
    writeVar('Scale', string.format('%.2f', s))
    SKIN:Bang('!Refresh')
end

function ZoomOut()
    local s = scale() - numVar('ScrollMouseIncrement', 0.05)
    if s < 0.45 then s = 0.45 end
    writeVar('Scale', string.format('%.2f', s))
    SKIN:Bang('!Refresh')
end
