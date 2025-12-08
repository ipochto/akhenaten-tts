#include "tts.hpp"

void parseCmdLineArguments(int argc, char* argv[], TTSConfig &config);

int main(int argc, char* argv[])
{
	TTSConfig config;
	parseCmdLineArguments(argc, argv, config);
	return 0;
}