#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../market/MarketTime.mqh"
#include "../util/Exception.mqh"
#include "../util/Util.mqh"
#include "News.mqh"


/**
 * This class retrieves market news information from a file and processes it, to determine when
 * the market should be closed because of a news. The file is downloaded periodically on the
 * computer, manually or by an external program, from the link below. If no file is found,
 * no news information is processed. The file location is: TerminalPath() + "/MQ4/Files/".
 *
 * https://cdn-nfs.faireconomy.media/ff_calendar_thisweek.csv
 */
class NewsFormat {
    public:
        void readNewsFromCalendar(News & []);

    private:
        static const string calendarFile_;
        static const string calendarHeader_;

        datetime formatDate(string, string);
};

const string NewsFormat::calendarFile_ = "ff_calendar_thisweek.csv";
const string NewsFormat::calendarHeader_ = "Title,Country,Date,Time,Impact,Forecast,Previous";

/**
 * Reads the local csv calendar file and formats its lines into an array of News objects.
 */
void NewsFormat::readNewsFromCalendar(News & news[]) {
    int fileHandle = FileOpen(calendarFile_, FILE_READ|FILE_CSV);

    // The first line of the file is the header
    const string fileHeader = FileReadString(fileHandle);

    if (fileHandle == INVALID_HANDLE || !FileIsExist(calendarFile_) || fileHeader != calendarHeader_) {
        ThrowException(__FUNCTION__, StringConcatenate(
            "Error when opening calendar file: ", calendarFile_));
Alert(TerminalPath());
Alert("NOT FOUND THE FILE: ", calendarFile_);
        return;
    }

    int index = 0;

    while (!FileIsEnding(fileHandle)) {
        const string line = FileReadString(fileHandle);

        string splitLine[];
        StringSplit(line, StringGetCharacter(",", 0), splitLine);

        ArrayResize(news, index + 1, 100);
        news[index].title = splitLine[0];
        news[index].country = splitLine[1];
        news[index].impact = splitLine[4];
        news[index].date = formatDate(splitLine[2], splitLine[3]);
        index++;
    }

    FileClose(fileHandle);
}

/**
 * Formats the date format of the csv calendar, to transform it into a datetime object.
 * It currently works for a date of the format: 12-27-2020 9:00pm.
 */
datetime NewsFormat::formatDate(string date, string time) {
    string splitDate[], splitTime[];

    StringSplit(date, StringGetCharacter("-", 0), splitDate);
    StringSplit(time, StringGetCharacter(":", 0), splitTime);

    int formattedHour = (int) splitTime[0];

    if (StringContains(splitTime[1], "pm") && formattedHour != 12) {
        formattedHour += 12;
    } else if (StringContains(splitTime[1], "am") && formattedHour == 12) {
        formattedHour -= 12;
    }

    datetime formattedDate = StringToTime(StringConcatenate(
        splitDate[2], ".", splitDate[0], ".", splitDate[1], " ", formattedHour, ":00"));

    // Converting the date from UTC to the broker time
    MarketTime marketTime;
    formattedDate += 3600 * marketTime.timeShiftInHours(marketTime.timeBroker(), TimeGMT());

    return formattedDate;
}
