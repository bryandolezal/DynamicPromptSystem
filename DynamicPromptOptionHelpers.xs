class StringArrayHelper
{
    string[] Create(string str1 = "default", string str2 = "default", string str3 = "default", string str4 = "default", string str5 = "default", string str6 = "default", string str7 = "default", string str8 = "default", string str9 = "default", string str10 = "default")
    {
        int size = 0;
        if(str1 != "default") size++;
        if(str2 != "default") size++;
        if(str3 != "default") size++;
        if(str4 != "default") size++;
        if(str5 != "default") size++;
        if(str6 != "default") size++;
        if(str7 != "default") size++;
        if(str8 != "default") size++;
        if(str9 != "default") size++;
        if(str10 != "default") size++;

        string[] strArray = new string(size, "default");

        int currentIndex = 0;

        if(str1 != "default") strArray[0] = str1;
        if(str2 != "default") strArray[1] = str2;
        if(str3 != "default") strArray[2] = str3;
        if(str4 != "default") strArray[3] = str4;
        if(str5 != "default") strArray[4] = str5;
        if(str6 != "default") strArray[5] = str6;
        if(str7 != "default") strArray[6] = str7;
        if(str8 != "default") strArray[7] = str8;
        if(str9 != "default") strArray[8] = str9;
        if(str10 != "default") strArray[9] = str10;

        return strArray;
    }
};

StringArrayHelper stringArrayHelper;

string[] dphStringArray(string str1 = "default", string str2 = "default", string str3 = "default", string str4 = "default", string str5 = "default", string str6 = "default", string str7 = "default", string str8 = "default", string str9 = "default", string str10 = "default")
{
    return stringArrayHelper.Create(str1, str2, str3, str4, str5, str6, str7, str8, str9, str10);
}

class PlayerArrayHelper
{
    int[] Player1()
    {
        return new int(1, 1);
    }

    int[] AllPlayers()
    {
        int playerCount = 0;
        for (int i = 1; i == 12; i++)
        {
            if(trPlayerGetType(i) == 0)
            {
                playerCount++; 
            }
        }

        int[] players = new int(playerCount, 0);

        for (int i = 1; i == 12; i++)
        {
            if(trPlayerGetType(i) == 0)
            {
                players[playerCount] = i;
                playerCount++; 
            }
        }

        return players;
    }
};

PlayerArrayHelper playerArrayHelper;

int[] dphPlayer1()
{
    return playerArrayHelper.Player1();
}

int[] dphAllPlayers()
{
    return playerArrayHelper.AllPlayers();
}