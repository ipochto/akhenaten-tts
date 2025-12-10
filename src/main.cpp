#include "tts.hpp"

bool parseCmdLineArguments(int argc, char* argv[], TTSConfig &config);

int main(int argc, char* argv[])
{
	TTSConfig config;
	if (!parseCmdLineArguments(argc, argv, config)) {
		return 1;
	}
	
	return 0;
}