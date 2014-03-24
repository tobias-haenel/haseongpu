/**
 * @author Erik Zenker
 * @author Carlchristian Eckert
 * @author Marius Melzer
 * @licence GPLv3
 *
 */

#ifndef PARSER_H
#define PARSER_H

#include <string>  /* string */
#include <iostream>
#include <fstream> /* ifstream */
#include <cstdlib> /* atof */
#include <vector> 
#include <logging.h>

#include <mesh.h>

enum RunMode { NONE, GPU_THREADED, CPU, GPU_MPI };

/**
 * @brief Parses a given file(filename) line by line.
 *        Each line should contain just one value
 *        and the value should be a number (short, unsigned,
 *        int, float, double).
 *
 * @param filename file to parse
 * @param vector contains the parsed values 
 *
 * @return 1 if parsing was succesful (file can be opened)
 * @return 0 otherwise
 **/
template <class T>
int fileToVector(const std::string filename, std::vector<T> *v){
  std::string line;
  std::ifstream fileStream; 
  T value = 0.0;

  fileStream.open(filename.c_str());
  if(fileStream.is_open()){
    while(fileStream.good()){
      std::getline(fileStream, line);
      value = (T) atof(line.c_str());
      if(isnan(value)){
	dout(V_ERROR) << "NAN in input data: " << filename << std::endl;
	exit(1);
      }
      v->push_back(value);
    }

  }
  else{
    dout(V_ERROR) << "Can't open file " << filename << std::endl;
    fileStream.close();
    return 1;
  }
  v->pop_back();
  fileStream.close();
  return 0;
  
}
/**
 * @brief Parses just one line(value) of a given file(filename).
 *        The value should be a number (short, unsigned,
 *        int, float, double).
 *
 * @param filename file to parse
 * @param value is the value which was parsed 
 *
 * @return 1 if parsing was succesful (file can be opened)
 * @return 0 otherwise
 **/
template <class T>
int fileToValue(const std::string filename, T &value){
  std::string line;
  std::ifstream fileStream; 

  fileStream.open(filename.c_str());
  if(fileStream.is_open()){
      std::getline(fileStream, line);
      value = (T) atof(line.c_str());
  }
  else{
    dout(V_ERROR) << "Can't open file " << filename << std::endl;
    fileStream.close();
    return 1;
  }
  fileStream.close();
  return 0;
  
}


void parseCommandLine(
    const int argc,
    char** argv,
    unsigned *raysPerSample,
    unsigned *maxRaysPerSample,
    std::string *inputPath,
    bool *writeVtk,
    std::string *compareLocation,
    RunMode *mode,
    bool *useReflections,
    unsigned *maxgpus,
    int *minSample_i,
    int *maxSample_i,
    unsigned *maxRepetitions,
    std::string *outputPath,
    double *mseThreshold
    );

int checkParameterValidity(
    const int argc,
    const unsigned raysPerSample,
    unsigned *maxRaysPerSample,
    const std::string inputPath,
    const unsigned deviceCount,
    const RunMode mode,
    unsigned *maxgpus,
    const int minSample_i,
    const int maxSample_i,
    const unsigned maxRepetitions,
    const std::string outputPath,
    double *mseThreshold
    );

void checkSampleRange(
	int* minSampleRange,
	int* maxSampleRange,
	const unsigned numberOfSamples
	);

std::vector<Mesh> parseMesh(std::string rootPath,
			    std::vector<unsigned> devices,
			    unsigned maxGpus);


#endif /* PARSER_H */
