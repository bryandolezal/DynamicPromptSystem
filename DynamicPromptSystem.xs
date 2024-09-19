class DynamicPromptSystem
{
    int generatedEventIDsStart = 644;
    bool initalized = false;
    int currentPromptUniqueID = 110000;

    int[] playersActivePromptID = default;
    bool[] playersStillInPrompt = default;

    int[] playerSelectedOptions = default;
    int[] playerPromptIndex = default;

    // Current Prompt Data
    int[] players = default;
    string messageText = "default";
    string[] options = default;
    int defaultOption = 1;
    int timeout = 10;
    int callbackEventID = -1;
    bool isMultiChoicePrompt = false;
    bool useDefaultOnTimeout = true;

    void Initalize()
    {
        playersActivePromptID = new int(13, 0);
        playersStillInPrompt = new bool(13, false);
        initalized = true;
    }

    void Reset()
    {
        playerSelectedOptions = new int(13, 0);
        playerPromptIndex = new int(13, 0);
        isMultiChoicePrompt = false;
    }

    void SendPromptToPlayers(int[] _players = default, string _messageText = "default", string[] _options = default, int _defaultOption = 1, int _timeout = -1, int _callbackEventID = -1, bool _useDefaultOnTimeout = true)
    {
        if(initalized == false)
        {
            Initalize();
        }

        Reset();

        currentPromptUniqueID = currentPromptUniqueID + 1;

        players = _players;
        messageText = _messageText;
        options = _options;
        defaultOption = _defaultOption;
        timeout = _timeout;
        callbackEventID = _callbackEventID;
        useDefaultOnTimeout = _useDefaultOnTimeout;

        // Add (default) to the default option
        options[_defaultOption - 1] = options[_defaultOption - 1] + " (default)";

        string option1Text = "default";
        string option2Text = "default";

        switch(options.size())
        {
            case 0:
            {
                return;
                break;
            }
            case 1:
            {   
                return;
                break;
            }
            case 2:
            {
                option1Text = options[0];
                option2Text = options[1];
                break;
            }
            default:
            {
                isMultiChoicePrompt = true;
                option1Text = options[_defaultOption - 1];
                option2Text = "Next Option";
                break;
            }
        }

        if(timeout > 0)
        {
            messageText = messageText + "\nYou have " + timeout + " seconds to choose.";
        }

        for(int i = 0; i < players.size(); i++)
        {
            int player = players[i];
        
            if(playersStillInPrompt[player] == false)
            {
                int choice1EventID = generatedEventIDsStart + ((player - 1) * 2);
                int choice2EventID = generatedEventIDsStart + ((player - 1) * 2) + 1;

                playersStillInPrompt[player] = true;
                playersActivePromptID[player] = currentPromptUniqueID;
                playerPromptIndex[player] = _defaultOption - 1;

                trShowChoiceDialogForPlayer(player, messageText, option1Text, choice1EventID, option2Text, choice2EventID);
            }
            else
            {
                trChatSend(0, "Player " + player + " is still in the last prompt. Automatically submitting the default option.");
                playerSelectedOptions[player] = defaultOption;
            }
        }

        xsEnableRule("_Dynamic_Prompt_Timeout_Monitor");
    }

    bool CheckAllPromptsAnswered()
    {
        for(int i = 1; i < 13; i++)
        {
            if(playersStillInPrompt[i] == true)
            {
                return false;
            }
        }

        return true;
    }

    int[] GetResults(int[] _players = default)
    {
        int[] results = new int(_players.size(), 0);

        for(int i = 0; i < _players.size(); i++)
        {
            results[i] = playerSelectedOptions[_players[i]];
        }

        return results;
    }

    int GetResultForPlayer(int player = 0)
    {
        return playerSelectedOptions[player];
    }

    void CompletePrompt()
    {
        if(useDefaultOnTimeout == true)
        {
            for(int i = 1; i < 13; i++)
            {
                if(playersStillInPrompt[i] == true)
                {
                    playerSelectedOptions[i] = defaultOption;
                    trChatSend(0, "Player " + i + " failed to select a prompt, defaulting to option " + defaultOption);
                }
            }
        }

        trEventFire(callbackEventID);
        xsDisableRule("_Dynamic_Prompt_Timeout_Monitor");
        currentPromptUniqueID = currentPromptUniqueID + 1;
    }

    void MultiChoicePromptShowNext(int player = 0)
    {
        playerPromptIndex[player] = playerPromptIndex[player] + 1;

        if(playerPromptIndex[player] >= options.size())
        {
            playerPromptIndex[player] = 0;
        }

        string option1Text = options[playerPromptIndex[player]];
        string option2Text = "Next Option";

        int choice1EventID = generatedEventIDsStart + ((player - 1) * 2);
        int choice2EventID = generatedEventIDsStart + ((player - 1) * 2) + 1;

        trShowChoiceDialogForPlayer(player, messageText, option1Text, choice1EventID, option2Text, choice2EventID);
    }

    void SubmitPromptChoice(int player = 0, int option = 0)
    {
        if(playersActivePromptID[player] != currentPromptUniqueID)
        {
            trChatSend(0, "Player " + player + " failed to choose in time. Ignoring their choice.");
            return;
        }

        if(option == 1)
        {
            if(isMultiChoicePrompt == false)
            {
                playerSelectedOptions[player] = 1;
                playersStillInPrompt[player] = false;
                return;
            }
            else
            {
                playerSelectedOptions[player] = playerPromptIndex[player] + 1;
                playersStillInPrompt[player] = false;
                return;
            }
            return;
        }

        if(option == 2)
        {
            if(isMultiChoicePrompt == false)
            {
                playerSelectedOptions[player] = 2;
                playersStillInPrompt[player] = false;
                return;
            }
            else
            {
                MultiChoicePromptShowNext(player);
                return;
            }
            return;
        }
    }
};

//==================================================================================================
//==================================================================================================

DynamicPromptSystem __dps;

void dpsSubmitPromptChoice(int player = 0, int option = 0)
{
    __dps.SubmitPromptChoice(player, option);
}

void dpsSendPromptToPlayers(int[] _players = default, string _messageText = "default", string[] _options = default, int _defaultOption = 1, int _timeout = -1, int _callbackEventID = -1, bool _useDefaultOnTimeout = true)
{
    __dps.SendPromptToPlayers(_players, _messageText, _options, _defaultOption, _timeout, _callbackEventID, _useDefaultOnTimeout);
}

int dpsGetResultForPlayer(int player = 0)
{
    return __dps.playerSelectedOptions[player];
}

int[] dpsGetResults(int[] _players = default)
{
    return __dps.GetResults(_players);
}

// void dpsSubmitPromptChoice (int player, int option)
// void dpsSendPromptToPlayers (int[] players, string messageText, string[] options, int defaultOption, int timeout, int callbackEventID, bool useDefaultOnTimeout)
// int dpsGetResultForPlayer (int player)

//==================================================================================================
//==================================================================================================

rule _Dynamic_Prompt_Timeout_Monitor
highFrequency
inactive
{
    if((xsGetTimeMS() - cActivationTime) >= 100)
    {
        bool allPromptsAnswered = __dps.CheckAllPromptsAnswered();
        bool promptExpired = false;

        if(__dps.timeout > 0)
        {
            if((xsGetTimeMS() - cActivationTime) >= __dps.timeout * 1000)
            {
                promptExpired = true;
            }
        }

        if(allPromptsAnswered == true || promptExpired)
        {
            __dps.CompletePrompt();
            xsDisableRule("_Dynamic_Prompt_Timeout_Monitor");
            trDisableRule("Dynamic_Prompt_Timeout_Monitor");
        }
    }
}

//==================================================================================================
//==================================================================================================

rule _DPS_Choice_1_P1
highFrequency
inactive
{
    dpsSubmitPromptChoice(1, 1);

    xsDisableRule("_DPS_Choice_1_P1");
    trDisableRule("DPS_Choice_1_P1");
}

rule _DPS_Choice_2_P1
highFrequency
inactive
{
    dpsSubmitPromptChoice(1, 2);

    xsDisableRule("_DPS_Choice_2_P1");
    trDisableRule("DPS_Choice_2_P1");
}

rule _DPS_Choice_1_P2
highFrequency
inactive
{
    dpsSubmitPromptChoice(2, 1);

    xsDisableRule("_DPS_Choice_1_P2");
    trDisableRule("DPS_Choice_1_P2");
}

rule _DPS_Choice_2_P2
highFrequency
inactive
{
    dpsSubmitPromptChoice(2, 2);

    xsDisableRule("_DPS_Choice_2_P2");
    trDisableRule("DPS_Choice_2_P2");
}

rule _DPS_Choice_1_P3
highFrequency
inactive
{
    dpsSubmitPromptChoice(3, 1);

    xsDisableRule("_DPS_Choice_1_P3");
    trDisableRule("DPS_Choice_1_P3");
}

rule _DPS_Choice_2_P3
highFrequency
inactive
{
    dpsSubmitPromptChoice(3, 2);

    xsDisableRule("_DPS_Choice_2_P3");
    trDisableRule("DPS_Choice_2_P3");
}

rule _DPS_Choice_1_P4
highFrequency
inactive
{
    dpsSubmitPromptChoice(4, 1);

    xsDisableRule("_DPS_Choice_1_P4");
    trDisableRule("DPS_Choice_1_P4");
}

rule _DPS_Choice_2_P4
highFrequency
inactive
{
    dpsSubmitPromptChoice(4, 2);

    xsDisableRule("_DPS_Choice_2_P4");
    trDisableRule("DPS_Choice_2_P4");
}

rule _DPS_Choice_1_P5
highFrequency
inactive
{
    dpsSubmitPromptChoice(5, 1);

    xsDisableRule("_DPS_Choice_1_P5");
    trDisableRule("DPS_Choice_1_P5");
}

rule _DPS_Choice_2_P5
highFrequency
inactive
{
    dpsSubmitPromptChoice(5, 2);

    xsDisableRule("_DPS_Choice_2_P5");
    trDisableRule("DPS_Choice_2_P5");
}

rule _DPS_Choice_1_P6
highFrequency
inactive
{
    dpsSubmitPromptChoice(6, 1);

    xsDisableRule("_DPS_Choice_1_P6");
    trDisableRule("DPS_Choice_1_P6");
}

rule _DPS_Choice_2_P6
highFrequency
inactive
{
    dpsSubmitPromptChoice(6, 2);

    xsDisableRule("_DPS_Choice_2_P6");
    trDisableRule("DPS_Choice_2_P6");
}

rule _DPS_Choice_1_P7
highFrequency
inactive
{
    dpsSubmitPromptChoice(7, 1);

    xsDisableRule("_DPS_Choice_1_P7");
    trDisableRule("DPS_Choice_1_P7");
}

rule _DPS_Choice_2_P7
highFrequency
inactive
{
    dpsSubmitPromptChoice(7, 2);

    xsDisableRule("_DPS_Choice_2_P7");
    trDisableRule("DPS_Choice_2_P7");
}

rule _DPS_Choice_1_P8
highFrequency
inactive
{
    dpsSubmitPromptChoice(8, 1);

    xsDisableRule("_DPS_Choice_1_P8");
    trDisableRule("DPS_Choice_1_P8");
}

rule _DPS_Choice_2_P8
highFrequency
inactive
{
    dpsSubmitPromptChoice(8, 2);

    xsDisableRule("_DPS_Choice_2_P8");
    trDisableRule("DPS_Choice_2_P8");
}

rule _DPS_Choice_1_P9
highFrequency
inactive
{
    dpsSubmitPromptChoice(9, 1);

    xsDisableRule("_DPS_Choice_1_P9");
    trDisableRule("DPS_Choice_1_P9");
}

rule _DPS_Choice_2_P9
highFrequency
inactive
{
    dpsSubmitPromptChoice(9, 2);

    xsDisableRule("_DPS_Choice_2_P9");
    trDisableRule("DPS_Choice_2_P9");
}

rule _DPS_Choice_1_P10
highFrequency
inactive
{
    dpsSubmitPromptChoice(10, 1);

    xsDisableRule("_DPS_Choice_1_P10");
    trDisableRule("DPS_Choice_1_P10");
}

rule _DPS_Choice_2_P10
highFrequency
inactive
{
    dpsSubmitPromptChoice(10, 2);

    xsDisableRule("_DPS_Choice_2_P10");
    trDisableRule("DPS_Choice_2_P10");
}

rule _DPS_Choice_1_P11
highFrequency
inactive
{
    dpsSubmitPromptChoice(11, 1);

    xsDisableRule("_DPS_Choice_1_P11");
    trDisableRule("DPS_Choice_1_P11");
}

rule _DPS_Choice_2_P11
highFrequency
inactive
{
    dpsSubmitPromptChoice(11, 2);

    xsDisableRule("_DPS_Choice_2_P11");
    trDisableRule("DPS_Choice_2_P11");
}

rule _DPS_Choice_1_P12
highFrequency
inactive
{
    dpsSubmitPromptChoice(12, 1);

    xsDisableRule("_DPS_Choice_1_P12");
    trDisableRule("DPS_Choice_1_P12");
}

rule _DPS_Choice_2_P12
highFrequency
inactive
{
    dpsSubmitPromptChoice(12, 2);

    xsDisableRule("_DPS_Choice_2_P12");
    trDisableRule("DPS_Choice_2_P12");
}