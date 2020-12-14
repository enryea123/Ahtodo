#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../Constants.mqh"


class UnitTest {
    public:
        UnitTest(string);
        ~UnitTest();

        template <typename T> void assertEquals(T, T, string);
        template <typename T> void assertNotEquals(T, T, string);
        void assertTrue(bool, string);
        void assertFalse(bool, string);

        bool hasDateDependentTestExpired();

    private:
        uint passedAssertions_;
        uint totalAssertions_;
        string testName_;

        template <typename T> void setFailure(T, T, string);
        void setFailure(string);
        void setSuccess(string);
        void getTestResult();
};

UnitTest::UnitTest(string testName):
    testName_(testName),
    passedAssertions_(0),
    totalAssertions_(0) {
}

UnitTest::~UnitTest() {
    getTestResult();
}

template <typename T> void UnitTest::assertEquals(T expected, T actual, string message = NULL) {
    if (expected == actual) {
        setSuccess(message);
    } else {
        setFailure(expected, actual, message);
    }
}

template <typename T> void UnitTest::assertNotEquals(T expected, T actual, string message = NULL) {
    if (expected != actual) {
        setSuccess(message);
    } else {
        setFailure(expected, actual, message);
    }
}

void UnitTest::assertTrue(bool condition, string message = NULL) {
    if (condition) {
        setSuccess(message);
    } else {
        setFailure(message);
    }
}

void UnitTest::assertFalse(bool condition, string message = NULL) {
    assertTrue(!condition, message);
}

bool UnitTest::hasDateDependentTestExpired() {
    if (TimeGMT() > BOT_TESTS_EXPIRATION_DATE) {
        return ThrowException(true, __FUNCTION__, StringConcatenate("Skipping expired test: ", testName_));
    }

    return false;
}

template <typename T> void UnitTest::setFailure(T expected, T actual, string message = NULL) {
    setFailure(message);
    Print("Expected <", expected, "> Actual <", actual, ">");
}

void UnitTest::setFailure(string message = NULL) {
    totalAssertions_++;
    Print("Assertion failed");

    if (message != NULL && message != "") {
        Print("Assertion failure message: ", message);
    }
}

void UnitTest::setSuccess(string message = NULL) {
    passedAssertions_++;
    totalAssertions_++;

    if (IS_DEBUG && message != NULL && message != "") {
        Print("Assertion succeeded: ", message);
    }
}

void UnitTest::getTestResult() {
    const string baseMessage = StringConcatenate("Test ", testName_,
        ": %s with ", passedAssertions_, "/", totalAssertions_);

    if (passedAssertions_ == totalAssertions_) {
        Print(StringFormat(baseMessage, "PASSED"));
    } else {
        ThrowFatalException(__FUNCTION__, StringFormat(baseMessage, "FAILED"));
    }
}
