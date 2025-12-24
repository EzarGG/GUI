--[[

\tEZR Interface Suite
\tby YourName

\tshlex  | Designing + Programming
\tiRay   | Programming
\tMax    | Programming
\tDamian | Programming

]]

if debugX then
\twarn('Initialising EZR')
end

local function getService(name)
\tlocal service = game:GetService(name)
\treturn if cloneref then cloneref(service) else service
end

-- Loads and executes a function hosted on a remote URL. Cancels the request if the requested URL takes too long to respond.
-- Errors with the function are caught and logged to the output
local function loadWithTimeout(url: string, timeout: number?): ...any
\tassert(type(url) == "string", "Expected string, got " .. type(url))
\ttimeout = timeout or 5
\tlocal requestCompleted = false
\tlocal success, result = false, nil

\tlocal requestThread = task.spawn(function()
\t\tlocal fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
\t\t-- If the request fails the content can be empty, even if fetchSuccess is true
\t\tif not fetchSuccess or #fetchResult == 0 then
\t\t\tif #fetchResult == 0 then
\t\t\t\tfetchResult = "Empty response" -- Set the error message
\t\t\tend
\t\t\tsuccess, result = false, fetchResult
\t\t\trequestCompleted = true
\t\t\treturn
\t\tend
\t\tlocal content = fetchResult -- Fetched content
\t\tlocal execSuccess, execResult = pcall(function()
\t\t\treturn loadstring(content)()
\t\tend)
\t\tsuccess, result = execSuccess, execResult
\t\trequestCompleted = true
\tend)

\tlocal timeoutThread = task.delay(timeout, function()
\t\tif not requestCompleted then
\t\t\twarn(`Request for {url} timed out after {timeout} seconds`)
\t\t\ttask.cancel(requestThread)
\t\t\tresult = "Request timed out"
\t\t\trequestCompleted = true
\t\tend
\tend)

\t-- Wait for completion or timeout
\twhile not requestCompleted do
\t\ttask.wait()
\tend
\t-- Cancel timeout thread if still running when request completes
\tif coroutine.status(timeoutThread) ~= "dead" then
\t\ttask.cancel(timeoutThread)
\tend
\tif not success then
\t\twarn(`Failed to process {url}: {result}`)
\tend
\treturn if success then result else nil
end

local requestsDisabled = true --getgenv and getgenv().DISABLE_RAYFIELD_REQUESTS
local InterfaceBuild = '3K3W'
local Release = "Build 1.68"
local EZRFolder = "EZR"  -- Changed from RayfieldFolder
local ConfigurationFolder = EZRFolder.."/Configurations"
local ConfigurationExtension = ".ezr"  -- Changed extension
local settingsTable = {
\tGeneral = {
\t\t-- if needs be in order just make getSetting(name)
\t\tezrOpen = {Type = 'bind', Value = 'K', Name = 'EZR Keybind'},  -- Changed from rayfieldOpen
\t\t-- buildwarnings
\t\t-- ezrprompts
\t},
\tSystem = {
\t\tusageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
\t}
}

-- Settings that have been overridden by the developer. These will not be saved to the user's configuration file
-- Overridden settings always take precedence over settings in the configuration file, and are cleared if the user changes the setting in the UI
local overriddenSettings: { [string]: any } = {} -- For example, overriddenSettings["System.ezrOpen"] = "J"
local function overrideSetting(category: string, name: string, value: any)
\toverriddenSettings[`{category}.{name}`] = value
end

local function getSetting(category: string, name: string): any
\tif overriddenSettings[`{category}.{name}`] ~= nil then
\t\treturn overriddenSettings[`{category}.{name}`]
\telseif settingsTable[category][name] ~= nil then
\t\treturn settingsTable[category][name].Value
\tend
end

-- If requests/analytics have been disabled by developer, set the user-facing setting to false as well
if requestsDisabled then
\toverrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

-- Environment Check
local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false -- Whether the UI elements in the settings page have been set to the proper values
local cachedSettings
local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/prompt.lua')
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

-- Validate prompt loaded correctly
if not prompt and not useStudio then
\twarn("Failed to load prompt library, using fallback")
\tprompt = {
\t\tcreate = function() end -- No-op fallback
\t}
end

local function loadSettings()
\tlocal file = nil

\tlocal success, result =\tpcall(function()
\t\ttask.spawn(function()
\t\t\tif isfolder and isfolder(EZRFolder) then  -- Changed folder name
\t\t\t\tif isfile and isfile(EZRFolder..'/settings'..ConfigurationExtension) then
\t\t\t\t\tfile = readfile(EZRFolder..'/settings'..ConfigurationExtension)
\t\t\t\tend
\t\t\tend

\t\t\t-- for debug in studio
\t\t\tif useStudio then
\t\t\t\tfile = [[
\t\t{"General":{"ezrOpen":{"Value":"K","Type":"bind","Name":"EZR Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"EZR Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}
\t]]
\t\t\tend

\t\t\tif file then
\t\t\t\tlocal success, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
\t\t\t\tif success then
\t\t\t\t\tfile = decodedFile
\t\t\t\telse
\t\t\t\t\tfile = {}
\t\t\t\tend
\t\t\telse
\t\t\t\tfile = {}
\t\t\tend

\t\t\tif not settingsCreated then 
\t\t\t\tcachedSettings = file
\t\t\t\treturn
\t\t\tend

\t\t\tif file ~= {} then
\t\t\t\tfor categoryName, settingCategory in pairs(settingsTable) do
\t\t\t\t\tif file[categoryName] then
\t\t\t\t\t\tfor settingName, setting in pairs(settingCategory) do
\t\t\t\t\t\t\tif file[categoryName][settingName] then
\t\t\t\t\t\t\t\tsetting.Value = file[categoryName][settingName].Value
\t\t\t\t\t\t\t\tsetting.Element:Set(getSetting(categoryName, settingName))
\t\t\t\t\t\t\tend
\t\t\t\t\t\tend
\t\t\t\t\tend
\t\t\t\tend
\t\t\tend
\t\t\tsettingsInitialized = true
\t\tend)
\tend)

\tif not success then 
\t\tif writefile then
\t\t\twarn('EZR had an issue accessing configuration saving capability.')  -- Changed message
\t\tend
\tend
end

if debugX then
\twarn('Now Loading Settings Configuration')
end

loadSettings()

if debugX then
\twarn('Settings Loaded')
end

local analyticsLib
local sendReport = function(ev_n, sc_n) warn("Failed to load report function") end
if not requestsDisabled then
\tif debugX then
\t\twarn('Querying Settings for Reporter Information')
\tend\t
\tanalyticsLib = loadWithTimeout("https://analytics.sirius.menu/script")
\tif not analyticsLib then
\t\twarn("Failed to load analytics reporter")
\t\tanalyticsLib = nil
\telseif analyticsLib and type(analyticsLib.load) == "function" then
\t\tanalyticsLib:load()
\telse
\t\twarn("Analytics library loaded but missing load function")
\t\tanalyticsLib = nil
\tend
\tsendReport = function(ev_n, sc_n)
\t\tif not (type(analyticsLib) == "table" and type(analyticsLib.isLoaded) == "function" and analyticsLib:isLoaded()) then
\t\t\twarn("Analytics library not loaded")
\t\t\treturn
\t\tend
\t\tif useStudio then
\t\t\tprint('Sending Analytics')
\t\telse
\t\t\tif debugX then warn('Reporting Analytics') end
\t\t\tanalyticsLib:report(
\t\t\t\t{
\t\t\t\t\t["name"] = ev_n,
\t\t\t\t\t["script"] = {["name"] = sc_n, ["version"] = Release}
\t\t\t\t},
\t\t\t\t{
\t\t\t\t\t["version"] = InterfaceBuild
\t\t\t\t}
\t\t\t)
\t\t\tif debugX then warn('Finished Report') end
\t\tend
\tend
\tif cachedSettings and (#cachedSettings == 0 or (cachedSettings.System and cachedSettings.System.usageAnalytics and cachedSettings.System.usageAnalytics.Value)) then
\t\tsendReport("execution", "EZR")  -- Changed from Rayfield
\telseif not cachedSettings then
\t\tsendReport("execution", "EZR")  -- Changed from Rayfield
\tend
end

local promptUser = 2

if promptUser == 1 and prompt and type(prompt.create) == "function" then
\tprompt.create(
\t\t'Be cautious when running scripts',
\t    [[Please be careful when running scripts from unknown developers. This script has already been ran.

<font transparency='0.3'>Some scripts may steal your items or in-game goods.</font>]],
\t\t'Okay',
\t\t'',
\t\tfunction()

\t\tend
\t)
end

if debugX then
\twarn('Moving on to continue initialisation')
end

local EZRLibrary = {  -- Changed from RayfieldLibrary
\tFlags = {},
\tTheme = {
\t\t-- All theme definitions remain the same...
\t\tDefault = {
\t\t\tTextColor = Color3.fromRGB(240, 240, 240),

\t\t\tBackground = Color3.fromRGB(25, 25, 25),
\t\t\tTopbar = Color3.fromRGB(34, 34, 34),
\t\t\tShadow = Color3.fromRGB(20, 20, 20),

\t\t\tNotificationBackground = Color3.fromRGB(20, 20, 20),
\t\t\tNotificationActionsBackground = Color3.fromRGB(230, 230, 230),

\t\t\tTabBackground = Color3.fromRGB(80, 80, 80),
\t\t\tTabStroke = Color3.fromRGB(85, 85, 85),
\t\t\tTabBackgroundSelected = Color3.fromRGB(210, 210, 210),
\t\t\tTabTextColor = Color3.fromRGB(240, 240, 240),
\t\t\tSelectedTabTextColor = Color3.fromRGB(50, 50, 50),

\t\t\tElementBackground = Color3.fromRGB(35, 35, 35),
\t\t\tElementBackgroundHover = Color3.fromRGB(40, 40, 40),
\t\t\tSecondaryElementBackground = Color3.fromRGB(25, 25, 25),
\t\t\tElementStroke = Color3.fromRGB(50, 50, 50),
\t\t\tSecondaryElementStroke = Color3.fromRGB(40, 40, 40),

\t\t\tSliderBackground = Color3.fromRGB(50, 138, 220),
\t\t\tSliderProgress = Color3.fromRGB(50, 138, 220),
\t\t\tSliderStroke = Color3.fromRGB(58, 163, 255),

\t\t\tToggleBackground = Color3.fromRGB(30, 30, 30),
\t\t\tToggleEnabled = Color3.fromRGB(0, 146, 214),
\t\t\tToggleDisabled = Color3.fromRGB(100, 100, 100),
\t\t\tToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
\t\t\tToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
\t\t\tToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
\t\t\tToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

\t\t\tDropdownSelected = Color3.fromRGB(40, 40, 40),
\t\t\tDropdownUnselected = Color3.fromRGB(30, 30, 30),

\t\t\tInputBackground = Color3.fromRGB(30, 30, 30),
\t\t\tInputStroke = Color3.fromRGB(65, 65, 65),
\t\t\tPlaceholderColor = Color3.fromRGB(178, 178, 178)
\t\t},
\t\t-- ... (all other themes remain unchanged)
\t}
}