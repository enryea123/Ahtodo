#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#define SingletonContructor(T) private: T() {}; public: static T * getInstance() {if (!instance) instance = new T(); return (T *) instance;}

template <typename T> class Singleton {
    protected:
        Singleton() {};
        static T * instance;

    public:
        // All the implementations need to
        // be manually deleted in DeInit
        static void deleteInstance() {
            if (instance) {
                delete instance;
                instance = NULL;
            }
        }
};

template <typename T> T * Singleton::instance = NULL;

class Ciao : public Singleton<Ciao> {
    SingletonContructor(Ciao);

    private:
        int count_;

    public:
        void printCiao() {
            Print("Ciao");
            count_++;
        }

        int getCount () {
            return count_;
        }
};
