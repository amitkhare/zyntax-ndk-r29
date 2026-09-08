#include <cstdio>

extern "C" int ndk_probe();

int main() {
    const int result = ndk_probe();
    std::printf("NDK r29 native result: %d\n", result);
    return result == 42 ? 0 : 1;
}
