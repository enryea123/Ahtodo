#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"


enum FilterType {
    Include,
    Exclude,
    Greater,
    Smaller,
};

class Filter {
    public:
        Filter(): values_(NULL), filterType_(Include) {}

        void setFilterType(FilterType filterType) {
            filterType_ = filterType;
            values_ = NULL;
        }

        // Setter
        template <typename T> void add(T v) {
            if (filterType_ == Include || filterType_ == Exclude) {
                values_ = StringConcatenate(values_, separator_, v, separator_);
            }
            if (filterType_ == Greater || filterType_ == Smaller) {
                values_ = v;
            }
        }
        template <typename T> void add(T v1, T v2) {add(v1); add(v2);}
        template <typename T> void add(T v1, T v2, T v3) {add(v1); add(v2); add(v3);}
        template <typename T> void add(T v1, T v2, T v3, T v4) {add(v1); add(v2); add(v3); add(v4);}
        template <typename T> void add(T & v[]) {for (int i = 0; i < ArraySize(v); i++) {add(v[i]);}}

        // Getter
        template <typename T> bool get(T v) {
            if (values_ == NULL) {
                return false;
            }

            if (filterType_ == Include || filterType_ == Exclude) {
                return StringContains(values_, StringConcatenate(separator_, v, separator_)) ?
                    !(filterType_ == Include) : (filterType_ == Include);
            }
            if (filterType_ == Greater || filterType_ == Smaller) {
                return (v > values_) ?
                    !(filterType_ == Greater) : (filterType_ == Greater);
            }

            return false;
        }

    private:
        static const string separator_;

        string values_;
        FilterType filterType_;
};

const string Filter::separator_ = "|";

class OrderFilter {
    public:
        Filter closeTime;
        Filter magicNumber;
        Filter profit;
        Filter symbol;
        Filter symbolFamily;
        Filter type;
};
