#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../Constants.mqh"


class UnitTest {
    public:
        UnitTest(string);
        ~UnitTest();

        template <typename T> bool assertEquals(T, T, string);
        template <typename T> bool assertEquals(T &, T &, string);
        template <typename T> bool assertEquals(T & [], T & [], string);
        template <typename T> bool assertNotEquals(T, T, string);
        template <typename T> bool assertNotEquals(T &, T &, string);
        bool assertTrue(bool, string);
        bool assertFalse(bool, string);

        bool hasDateDependentTestExpired();

    private:
        uint passedAssertions_;
        uint totalAssertions_;
        string testName_;

        template <typename T> bool setFailure(T, T, string);
        bool setSuccess(string);
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

template <typename T> bool UnitTest::assertEquals(T expected, T actual, string message = NULL) {
    if (expected == actual) {
        return setSuccess(message);
    } else {
        return setFailure(expected, actual, message);
    }
}

template <typename T> bool UnitTest::assertEquals(T & expected, T & actual, string message = NULL) {
    if (expected == actual) {
        return setSuccess(message);
    } else {
        return setFailure(expected.toString(), actual.toString(), message);
    }
}

template <typename T> bool UnitTest::assertEquals(T & expected[], T & actual[], string message = NULL) {
    if (!assertEquals(StringConcatenate("size: ", ArraySize(expected)),
        StringConcatenate("size: ", ArraySize(actual)), message)) {
        return false;
    }

    for (int i = 0; i < ArraySize(expected); i++) {
        if (!assertEquals(expected[i], actual[i], message)) {
            return false;
        }
    }

    return setSuccess(message);
}

template <typename T> bool UnitTest::assertNotEquals(T expected, T actual, string message = NULL) {
    if (expected != actual) {
        return setSuccess(message);
    } else {
        return setFailure(expected, actual, message);
    }
}

template <typename T> bool UnitTest::assertNotEquals(T & expected, T & actual, string message = NULL) {
    if (expected != actual) {
        return setSuccess(message);
    } else {
        return setFailure(expected.toString(), actual.toString(), message);
    }
}

bool UnitTest::assertTrue(bool condition, string message = NULL) {
    if (condition) {
        return setSuccess(message);
    } else {
        return setFailure("true", "false", message);
    }
}

bool UnitTest::assertFalse(bool condition, string message = NULL) {
    if (!condition) {
        return setSuccess(message);
    } else {
        return setFailure("false", "true", message);
    }
}

bool UnitTest::hasDateDependentTestExpired() {
    if (TimeGMT() > BOT_TESTS_EXPIRATION_DATE) {
        return ThrowException(true, __FUNCTION__, StringConcatenate("Skipping expired test: ", testName_));
    }

    return false;
}

template <typename T> bool UnitTest::setFailure(T expected, T actual, string message = NULL) {
    totalAssertions_++;
    Print("Assertion failed");

    if (message != NULL && message != "") {
        Print("Assertion failure message: ", message);
    }

    Print("Expected <", expected, "> Actual <", actual, ">");

    return false;
}

bool UnitTest::setSuccess(string message = NULL) {
    passedAssertions_++;
    totalAssertions_++;

    if (IS_DEBUG && message != NULL && message != "") {
        Print("Assertion succeeded: ", message);
    }

    return true;
}

void UnitTest::getTestResult() {
    const string baseMessage = StringConcatenate("Test ", testName_,
        " %s with ", passedAssertions_, "/", totalAssertions_);

    if (passedAssertions_ == totalAssertions_) {
        Print(StringFormat(baseMessage, "PASSED"));
    } else {
        ThrowFatalException(__FUNCTION__, StringFormat(baseMessage, "FAILED"));
    }
}
