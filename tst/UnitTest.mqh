#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../src/Constants.mqh"


class UnitTest{
    public:
        UnitTest(string);
        ~UnitTest();

    //protected:
        void assertEquals(color, color, string);
        void assertEquals(int, int, string);
        void assertEquals(string, string, string);

        //void assertNotEquals(int, int);

        void assertNotNull(double, string);
        void assertTrue(bool, string);
        void assertFalse(bool, string);

        void getTestResult();

    private:
        int passedAssertions_;
        int totalAssertions_;

        string testName_;

        void setSuccess(string);
        void setFailure(string);
        void setFailure(int, int, string);
        void setFailure(string, string, string);
};

UnitTest::UnitTest(string testName):
    testName_(testName),
    passedAssertions_(0),
    totalAssertions_(0){
}

UnitTest::~UnitTest(){
    getTestResult();
}

void UnitTest::setSuccess(string message = NULL){
    passedAssertions_++;
    totalAssertions_++;

    if(IS_DEBUG && message != NULL && message != "")
        Print("Assertion succeeded: ", message);
}

void UnitTest::setFailure(string message = NULL){
    totalAssertions_++;
    Print("Assertion failed");

    if(message != NULL && message != "")
        Print("Assertion failure message: ", message);
}

void UnitTest::setFailure(int expected, int actual, string message = NULL){
    setFailure(message);
    Print("Expected <", expected, "> Actual <", actual, ">");
}

void UnitTest::setFailure(string expected, string actual, string message = NULL){
    setFailure(message);
    Print("Expected <", expected, "> Actual <", actual, ">");
}

void UnitTest::assertEquals(color expected, color actual, string message = NULL){
    if(expected == actual)
        setSuccess(message);
    else
        setFailure(message);
}

void UnitTest::assertEquals(int expected, int actual, string message = NULL){
    if(expected == actual)
        setSuccess(message);
    else
        setFailure(expected, actual, message);
}

void UnitTest::assertEquals(string expected, string actual, string message = NULL){
    if(expected == actual)
        setSuccess(message);
    else
        setFailure(expected, actual, message);
}

void UnitTest::assertNotNull(double value, string message = NULL){
    if(value == NULL)
        setFailure(message);
}

void UnitTest::assertTrue(bool condition, string message = NULL){
    if(condition)
        setSuccess(message);
    else
        setFailure(message);
}

void UnitTest::assertFalse(bool condition, string message = NULL){
    if(condition)
        setFailure(message);
    else
        setSuccess(message);
}

void UnitTest::getTestResult(){
    if(passedAssertions_ > 0 && passedAssertions_ == totalAssertions_)
        Print("Test ", testName_, ": PASSED");
    else
        ThrowFatalException(StringConcatenate("Test ", testName_, ": FAILED"));
}
