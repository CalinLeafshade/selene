--util

math.randomseed(os.time()) math.random() math.random() math.random()

function string.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end