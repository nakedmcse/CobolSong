       IDENTIFICATION DIVISION.
       PROGRAM-ID. SongForVictoria.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  ENV-VARIABLE-NAME   PIC X(20) VALUE 'OPENAI_API_KEY'.
       01  ENV-API-KEY         PIC X(51).
       01  CMD                 PIC X(4096).
       01  QUERY               PIC X(900).
       01  PARSECMD            PIC X(80).
       01  REMCMD              PIC X(80).
       01  ERR                 PIC 9(4) COMP-5.

       PROCEDURE DIVISION.
       MAIN-PARAGRAPH.
           *> Build Prompt
           STRING
           "Create a music video challenge for the month Oct 2023 ",
           "and would like you to return a theme ",
           "for each day in the form of \""a video featuring\"" ",
           "followed by the theme for the day. ",
           "Two days should be free choice days with no theme, ",
           "and should not be on consecutive days. ",
           "Themes should not exactly repeat, and should not be ",
           "direct types of music. ",
           "Try to space out similar themes by 7 days. ",
           "Return just the data in the form of ",
           "REM YYYY-MM-DD CAL theme, one per line for each day. ",
           "The rem at the start and exact line format is important."
           DELIMITED BY SIZE
           INTO QUERY

           *> Get environment variable API Key
           ACCEPT ENV-API-KEY FROM ENVIRONMENT "OPENAI_API_KEY"

           IF ENV-API-KEY NOT EQUAL SPACES
               *> Call OpenAI API using Curl
               STRING
               "curl -s https://api.openai.com/v1/chat/completions ",
               "-H ""Content-Type: application/json"" ",
               "-H ""Authorization: Bearer ", ENV-API-KEY, """ ",
               "-d '{""model"": ""gpt-4"", ",
               """messages"":[{""role"": ""user"", ""content"": """, 
               QUERY, 
               """}], ""temperature"":0.7}' > tmpout.json"
               DELIMITED BY SIZE
               INTO CMD
               CALL "SYSTEM" USING CMD RETURNING ERR
               IF ERR NOT EQUAL ZERO
                   DISPLAY 'API Call failed with code: ' ERR
               END-IF

               *> Parse return JSON
               STRING
               "cat tmpout.json| jq -r '.choices[0].message.content' ",
               "> song.cal"
               DELIMITED BY SIZE INTO PARSECMD
               CALL "SYSTEM" USING PARSECMD RETURNING ERR
               IF ERR NOT EQUAL ZERO
                   DISPLAY 'Parse JSON failed with code: ' ERR
               END-IF

               *> Call remind to draw calendar
               STRING
               "remind -cu -w140,, song.cal October 2023 ",
               "> song.txt"
               DELIMITED BY SIZE INTO REMCMD
               CALL "SYSTEM" USING REMCMD RETURNING ERR
               IF ERR NOT EQUAL ZERO
                   DISPLAY 'Build Calendar failed with code: ' ERR
               END-IF

           ELSE
               DISPLAY 'Error: API Key not found!'
           END-IF

           STOP RUN.
