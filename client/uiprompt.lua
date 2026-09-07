UIPrompt = {}

local promptGroup = GetRandomIntInRange(0, 0xffffff)
local Prompt = nil

UIPrompt.activate = function(text)
    local label = VarString(10, 'LITERAL_STRING', text)
    UiPromptSetActiveGroupThisFrame(promptGroup, label, 0, 0, 0, 0)
end

UIPrompt.initialize = function()
    Prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(Prompt, Config.InteractKey)
    UiPromptSetText(Prompt, VarString(10, 'LITERAL_STRING', 'Interact'))
    UiPromptSetEnabled(Prompt, true)
    UiPromptSetVisible(Prompt, true)
    UiPromptSetStandardMode(Prompt, true)
    UiPromptSetGroup(Prompt, promptGroup, 0)
    UiPromptRegisterEnd(Prompt)
end

UIPrompt.completedThisFrame = function()
    return UiPromptHasStandardModeCompleted(Prompt, 0)
end
