#include <numeric>
#include <stdexcept>
#include <vector>

extern "C" int ndk_c_probe(void);

extern "C" int ndk_probe() {
    const std::vector<int> values{ndk_c_probe(), 12, 24};
    try {
        throw std::runtime_error("exception runtime");
    } catch (const std::runtime_error&) {
        return std::accumulate(values.begin(), values.end(), 0);
    }
}
