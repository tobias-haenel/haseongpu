// Libraries
#include "stdio.h"
#include "stdlib.h"
#include "math.h"
#include "vector_types.h"
#include "assert.h"
#include "string.h"
#include <vector>
#include "curand_kernel.h"


// User header files
#include "datatypes.h"
#include "geometry.h"
#include "datatypes.h"
#include "generate_testdata.h"
#include "print.h"
#include "geometry_gpu.h"
#include "ase_bruteforce_kernel.h"
#include "ase_bruteforce_cpu.h"
#include "testdata_transposed.h"
#include "ray_propagation_gpu.h"
#include "buildgrid.h"
#include "parser.h"

int main(int argc, char **argv){
  unsigned raysTotal;
  char runmode[100];
  char experimentLocation[256];
  float runtime = 0.0;
  unsigned blocks = 0;
  unsigned threads = 0;
  
  // Experimentdata

  //std::vector<double> * betas = new std::vector<double>;
  std::vector<double> * betaValues = new std::vector<double>;
  //std::vector<double> * n_x = new std::vector<double>;
  std::vector<double> * xOfNormals = new std::vector<double>;
  //std::vector<double> * n_y = new std::vector<double>;
  std::vector<double> * yOfNormals = new std::vector<double>;
  //std::vector<unsigned> * cell_types = new std::vector<unsigned>;
  std::vector<unsigned> * cellTypes = new std::vector<unsigned>;
  //std::vector<unsigned> * t_in = new std::vector<unsigned>;
  std::vector<unsigned> * triangleIndices = new std::vector<unsigned>;
  //std::vector<int> * forbidden = new std::vector<int>;
  std::vector<int> * forbidden = new std::vector<int>;
  //std::vector<int> * neighbors = new std::vector<int>;
  std::vector<int> * neighbors = new std::vector<int>;
  //std::vector<int> * n_p = new std::vector<int>;
  std::vector<int> * positionsOfNormalVectors = new std::vector<int>;
  //std::vector<int> * p_in = new std::vector<int>;
  std::vector<int> * points = new std::vector<int>;
  //float clad_abs = 0;
  float cladAbsorption = 0;
  //float clad_num = 0;
  float cladNumber = 0;
  //float n_tot = 0;
  float nTot = 0;
  //float sigma_a = 0;
  float sigmaA = 0;
  //float sigma_e = 0;
  float sigmaE = 0;
  //unsigned size_p = 0;
  unsigned numberOfPoints = 0;
  //unsigned numberOfTriangles = 0;
  unsigned numberOfTriangles = 0;
  //unsigned mesh_z = 0;
  unsigned numberOfLevels = 0;
  //float z_mesh = 1;
  float thicknessOfPrism = 1;

  // Parse Commandline
  if(argc <= 1){
    fprintf(stderr, "C No commandline arguments found\n");
    fprintf(stderr, "C Usage    : ./octrace --mode=[runmode] --rays=[number of rays] --experiment=[location to .zip]\n");
    fprintf(stderr, "C Runmodes : bruteforce_gpu\n");
    fprintf(stderr, "             ray_propagation_gpu\n");
    return 0;
  }
  
  // Parse number of rays
  unsigned i;
  for(i=1; i < argc; ++i){
    if(strncmp(argv[i], "--rays=", 6) == 0){
      const char* pos = strrchr(argv[i],'=');
      raysTotal = atoi(pos+1);
    }
  }

  // Parse location of experiements
  for(i=1; i < argc; ++i){
    if(strncmp(argv[i], "--experiment=", 12) == 0){
      memcpy (experimentLocation, argv[i]+13, strlen(argv[i])-13 );
    } 
  }

  if(parse(experimentLocation, betas, n_x, n_y, cell_types, t_in, forbidden, neighbors, n_p, p_in, &clad_abs, &clad_num, &n_tot, &sigma_a, &sigma_e, &size_p, &numberOfTriangles, &mesh_z)){
    fprintf(stderr, "C Had problems while parsing experiment data\n");
    return 1;
  }

  // Debug
  /*
  fprintf(stderr, "clad_abs: %f\n", clad_abs);
  fprintf(stderr, "clad_num: %f\n", clad_num);
  fprintf(stderr, "n_tot: %e\n", n_tot);
  fprintf(stderr, "sigma_a: %e\n", sigma_a);
  fprintf(stderr, "sigma_e: %e\n", sigma_e);
  fprintf(stderr, "size_p: %d\n", size_p);
  fprintf(stderr, "numberOfTriangles: %d\n", numberOfTriangles); 
  fprintf(stderr, "mesh_z: %d\n", mesh_z);
  fprintf(stderr, "cell types size: %d\n", cell_types->size());
  fprintf(stderr, "p_in size: %d\n", p_in->size());
  */

  // Generate testdata
  fprintf(stderr, "C Generate Testdata\n");
  std::vector<PrismCu>  *prisms = generatePrismsFromTestdata(mesh_z, p_in, size_p, t_in, numberOfTriangles, z_mesh);
  std::vector<PointCu> *samples = generateSamplesFromTestdata(mesh_z, p_in, size_p);
  std::vector<double>      *ase = new std::vector<double>(samples->size(), 0);
  raysTotal = (unsigned)pow(2,17);

  // Run Experiment
  for(i=1; i < argc; ++i){
    if(strncmp(argv[i], "--mode=", 6) == 0){
      if(strstr(argv[i], "bruteforce_gpu") != 0){
	// threads and blocks will be set in the following function (by reference)
  	runtime = runAseBruteforceGpu(samples, prisms, betas, ase, threads, blocks, rays_total);
	strcpy(runmode, "Bruteforce GPU");
	break;
      }
      else if(strstr(argv[i], "ray_propagation_gpu") != 0){
	// threads and blocks will be set in the following function (by reference)
	runtime = runRayPropagationGpu(
			ase,
			threads, 
			blocks, 
			raysTotal,
			betaValues,
			xOfNormals,
			yOfNormals,
			cellTypes,
			triangleIndices,
			forbidden,
			neighbors,
			positionsOfNormalVectors,
			points,
			cladAbsorption,
			cladNumber,
			nTot,
			sigmaA,
			sigmaE,
			numberOfPoints,
			numberOfTriangles,
			numberOfLevels,
			thicknessOfPrism);
	strcpy(runmode, "Naive Ray Propagation GPU");
	break;
      }
    
    }

  }

  // Print Solution
  unsigned sample_i;
  fprintf(stderr, "C Solutions\n");
  for(sample_i = 0; sample_i < ase->size(); ++sample_i){
    fprintf(stderr, "C ASE PHI of sample %d: %.80f\n", sample_i, ase->at(sample_i));

  }

  // Print statistics
  fprintf(stderr, "\n");
  fprintf(stderr, "C Statistics\n");
  fprintf(stderr, "C Prism             : %d\n", (int) prisms->size());
  fprintf(stderr, "C Samples           : %d\n", (int) samples->size());
  fprintf(stderr, "C Rays/Sample       : %d\n", raysTotal / samples->size());
  fprintf(stderr, "C Rays Total        : %d\n", raysTotal);
  fprintf(stderr, "C GPU Blocks        : %d\n", blocks);
  fprintf(stderr, "C GPU Threads/Block : %d\n", threads);
  fprintf(stderr, "C GPU Threads Total : %d\n", threads * blocks);
  fprintf(stderr, "C Runmode           : %s \n", runmode);
  fprintf(stderr, "C Runtime           : %f s\n", runtime / 1000.0);
  fprintf(stderr, "\n");

  return 0;
}


