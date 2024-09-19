//include "scripts\dynamic_prompt_system\DynamicPromptOptionHelpers.xs";
//include "scripts\dynamic_prompt_system\DynamicPromptSystem.xs";

class GameSettingOption
{
    string optionText = "default";
};

class GameSetting
{
    string settingName = "default";
    string settingDisplayText = "default";
    bool isPerPlayer = false;
    bool processWhenOptionIsSelected = false;

    GameSettingOption[] options = default;
    int[] targetedPlayers = default;
    int[] playerSelectedOptions = default;
    int defaultOption = 1;

    int[] eventIDs = default;
    string[] ruleNames = default;

    string[] GetOptionStrings()
    {
        int size = options.size();

        string[] optionStrings = new string(size, "default");

        for(int i = 0; i < options.size(); i++)
        {
            GameSettingOption gso = options[i];
            optionStrings[i] = gso.optionText;
        }

        return optionStrings;
    }

    string[] GetOptionsArray()
    {
        int size = options.size();

        string[] optionStrings = new string(size, "default");

        for(int i = 0; i < options.size(); i++)
        {
            GameSettingOption gso = options[i];
            optionStrings[i] = gso.optionText;
        }

        return optionStrings;
    }
};

class CustomGameSettings
{
    GameSetting[] gameSettings = default;

    bool waitingForPromptToComplete = false;
    int promptedGameSettingIndex = 0;
    int promptType = 0;
    int callbackEventID = -1;

    // For running prompts
    int promptArrayIndex = 0;
    int[] promptArray = default;
    int promptArrayCallbackEventID = -1;

    int AddGameSetting(string _settingName = "default", string _settingDisplayText = "default", string[] _options = default, int[] _targetedPlayers = default, int _defaultOption = 1, string[] _ruleNames = default, bool _setWithDefault = false)
    {
        GameSetting newGameSetting;

        newGameSetting.settingName = _settingName;
        newGameSetting.settingDisplayText = _settingDisplayText;

        for(int i = 0; i < _options.size(); i++)
        {
            GameSettingOption newOption;
            newOption.optionText = _options[i];
            newGameSetting.options.add(newOption);
        }

        newGameSetting.targetedPlayers = _targetedPlayers;
        newGameSetting.playerSelectedOptions = new int(13, 0);
        newGameSetting.defaultOption = _defaultOption;
        newGameSetting.ruleNames = _ruleNames;

        if(_setWithDefault == true)
        {
            for(int i = 0; i < _targetedPlayers.size(); i++)
            {
                int playerIndex = _targetedPlayers[i];
                newGameSetting.playerSelectedOptions[playerIndex] = _defaultOption;
            }
        }

        gameSettings.add(newGameSetting);

        return gameSettings.size() - 1;
    }

    void SendPromptToTargetedPlayers(int _gameSettingIndex = 0, int _timeout = 10, bool useDefaultOnTimeout = true, int _callbackEventID = -1)
    {
        if(waitingForPromptToComplete == true)
        {
            return;
        }

        waitingForPromptToComplete = true;
        promptedGameSettingIndex = _gameSettingIndex;
        promptType = 1;
        callbackEventID = _callbackEventID;

        GameSetting gameSetting = gameSettings[_gameSettingIndex];
        dpsSendPromptToPlayers(gameSetting.targetedPlayers, gameSetting.settingDisplayText, gameSetting.GetOptionStrings(), gameSetting.defaultOption, _timeout, 110000, useDefaultOnTimeout);
    }

    // Is called when the prompt is completed
    // Saves the results of the prompt to the game setting
    void ProcessPrompt()
    {
        switch(promptType)
        {
            case 1: // SendPromptToTargetedPlayers
            {
                GameSetting gameSetting = gameSettings[promptedGameSettingIndex];

                for(int i = 0; i < gameSetting.targetedPlayers.size(); i++)
                {
                    int playerIndex = gameSetting.targetedPlayers[i];
                    gameSetting.playerSelectedOptions[playerIndex] = dpsGetResultForPlayer(playerIndex);
                }

                gameSettings[promptedGameSettingIndex] = gameSetting;
                waitingForPromptToComplete = false;
                trEventFire(callbackEventID);
                break;
            }
        }
    }

    void ProcessGameSetting(int _gameSettingIndex = 0)
    {   
        GameSetting gameSetting = gameSettings[_gameSettingIndex];

        for(int i = 0; i < gameSetting.eventIDs.size(); i++)
        {
            trEventFire(gameSetting.eventIDs[i]);
        }

        for(int h = 0; h < gameSetting.ruleNames.size(); h++)
        {
            xsEnableRule(gameSetting.ruleNames[h]);
        }
    }

    void ProcessGameSettingArray(int[] _gameSettingIndices = default)
    {
        for(int i = 0; i < _gameSettingIndices.size(); i++)
        {
            ProcessGameSetting(_gameSettingIndices[i]);
        }
    }

    int GetSelectedOption(int _gameSettingIndex = 0, int _playerIndex = 0)
    {
        GameSetting gameSetting = gameSettings[_gameSettingIndex];

        return gameSetting.playerSelectedOptions[_playerIndex];
    }

    string[] GetOptionsArray(int _gameSettingIndex = 0)
    {
        GameSetting gameSetting = gameSettings[_gameSettingIndex];

        return gameSetting.GetOptionsArray();
    }
};

//==================================================================================================
//==================================================================================================

CustomGameSettings __cgs;

int cgsAddSetting(string _settingName = "default", string _settingDisplayText = "default", string[] _options = default, int[] _targetedPlayers = default, int _defaultOption = 1, string[] _ruleNames = default, bool _setWithDefault = false)
{
    return __cgs.AddGameSetting(_settingName, _settingDisplayText, _options, _targetedPlayers, _defaultOption, _ruleNames, _setWithDefault);
}

void cgsPromptAndProcess(int[] _promptArray = default, int _callbackEventID = -1)
{
    __cgs.promptArrayIndex = 0;
    __cgs.promptArray = _promptArray;
    __cgs.promptArrayCallbackEventID = _callbackEventID;

    trEventFire(110001);
}

void cgsProcessSettings(int[] _promptArray = default, int _callbackEventID = -1)
{
    __cgs.ProcessGameSettingArray(_promptArray);
    trEventFire(_callbackEventID);
}

int cgsGetSelectedOption(int _gameSettingIndex = 0, int _playerIndex = 0)
{
    return __cgs.GetSelectedOption(_gameSettingIndex, _playerIndex);
}

string[] cgsGetOptions(int _gameSettingIndex = 0)
{
    return __cgs.GetOptionsArray(_gameSettingIndex);
}

//==================================================================================================
//==================================================================================================

void gameSettingsEventHandler(int eventID = -1)
{
    switch (eventID)
    {
        case 110000:
        {
            __cgs.ProcessPrompt();
            
            break;
        }
        case 110001:
        {
            if(__cgs.promptArrayIndex < __cgs.promptArray.size())
            {
                __cgs.SendPromptToTargetedPlayers(__cgs.promptArray[__cgs.promptArrayIndex], 10, true, 110001);
                __cgs.promptArrayIndex++;
            }
            else
            {
                __cgs.ProcessGameSettingArray(__cgs.promptArray);
                trEventFire(__cgs.promptArrayCallbackEventID);
            }
            break;
        }
    }
}

rule _Register_Game_Settings_Event_Handlers
highFrequency
runImmediately
active
{
    trEventSetHandler(110000, "gameSettingsEventHandler");
    trEventSetHandler(110001, "gameSettingsEventHandler");

    xsDisableRule("_Register_Game_Settings_Event_Handlers");
    trDisableRule("Register_Game_Settings_Event_Handlers");
}

rule _Debug_Game_Settings
highFrequency
runImmediately
inactive
{
    for(int i = 0; i < __cgs.gameSettings.size(); i++)
    {
        GameSetting gs = __cgs.gameSettings[i];
        trChatSend(1, "Setting Name: " + gs.settingName);

        for(int j = 0; j < gs.targetedPlayers.size(); j++)
        {
            trChatSend(1, "Player " + gs.targetedPlayers[j] + " Selected Option: " + gs.playerSelectedOptions[gs.targetedPlayers[j]]);
        }
    }

    xsDisableRule("_Debug_Game_Settings");
    trDisableRule("Debug_Game_Settings");
}