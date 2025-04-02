CREATE OR ALTER PROCEDURE GenerateLetterCombinations
    @Letters NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Remove spaces and split the input letters into a table
    DECLARE @LetterTable TABLE (Letter NVARCHAR(1));
    INSERT INTO @LetterTable (Letter)
    SELECT TRIM(value) FROM STRING_SPLIT(@Letters, ',') WHERE value <> '';

    -- Get the number of distinct letters
    DECLARE @Length INT = (SELECT COUNT(*) FROM @LetterTable);

    -- Check for valid input
    IF @Length < 1
    BEGIN
        RAISERROR('Invalid input: At least one letter is required.', 16, 1);
        RETURN;
    END

    -- Temporary table to store combinations
    CREATE TABLE #temp_wordtable (rn INT, word NVARCHAR(50));

    -- Insert initial letters into the temporary table
    INSERT INTO #temp_wordtable (rn, word)
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn, Letter
    FROM @LetterTable;

    -- Generate combinations iteratively
    DECLARE @i INT = 1;
    WHILE @i < @Length
    BEGIN
        INSERT INTO #temp_wordtable (rn, word)
        SELECT 
            ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,
            CONCAT(w1.word, w2.Letter)
        FROM #temp_wordtable w1
        CROSS JOIN @LetterTable w2
        WHERE LEN(w1.word) = @i;

        SET @i = @i + 1;
    END

    -- Select meaningful words from the dictionary
    SELECT DISTINCT w.word
    FROM [dbo].[Farsidictionary11] AS D
    JOIN #temp_wordtable AS w ON D.word = w.word
    WHERE LEN(w.word) <= @Length;

    -- Clean up
    DROP TABLE #temp_wordtable;
END