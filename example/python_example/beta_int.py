##################################################################################
# Copyright 2013 Daniel Albach, Erik Zenker, Carlchristian Eckert
#
# This file is part of HASEonGPU
#
# HASEonGPU is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# HASEonGPU is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with HASEonGPU.
# If not, see <http://www.gnu.org/licenses/>.
#################################################################################

#  function corresponding to the gain calculation
# this will be more versatile, because with the proper values given, you
# can call pump and amplification with the same routine
#                   Daniel Albach       2008/03/24 
import numpy as np

def beta_int(beta_crystal,pulse,phy_const,crystal,steps,int_field,mode, Ntot_gradient):

    # declarations
    int_field['max_ems, i = np.max(int_field.s_ems), np.argmax(int_field.s_ems)']
    int_field['max_abs = int_field.s_abs[i]']
    sigma_abs = int_field['max_abs'] #cm^2
    sigma_ems = int_field['max_ems'] #cm^2

    # discritization
    steps_time = steps['time']
    steps_crystal = steps['crys']

    # extracting the constants
    c = phy_const['c']
    h = phy_const['h']
    N_1percent = phy_const['N1per']

    # extracting the "pump" constants
    I_pump = int_field['I'] #W/cm�
    tau_pump = int_field['T']
    wavelength = int_field['wavelength'] #m

    #extracting the crystal constants
    doping = crystal['doping']
    tau_fluo = crystal['tfluo']
    crystal_length = crystal['length #cm']
    exp_factor = crystal['nlexp']

    #total doping concentration
    Ntot = N_1percent * doping

    time_step = tau_pump/(steps_time-1)
    crystal_step = crystal_length/(steps_crystal-1)

    # prepare the vectors with zeros
    beta_store = np.zeros(steps_crystal,steps_time)
    pump = np.zeros(steps_crystal,1)
    pump_l = np.zeros(steps_crystal,1)
    Ntot_gradient = np.zeros(steps_crystal,1)

    # exponential gradient
    for igradient in range(steps_crystal):
        Ntot_gradient[igradient] = Ntot*np.exp(np.log(exp_factor)/crystal_length*(igradient-1)*crystal_step)
        

        for itime in range(steps_time):
        #     now the first slice moves
        #     go with it into the slices of the crystal 
        #     for the first slice the it is always Ip, the second gets the
        #     estimation with an average beta from m->m+1 with an exponential
        #     function and so on - boundaries!
            pump[0] = I_pump
            
        #   this is the positive direction
            for icrys in range(steps_crystal-1): 
        #       step one is from point one to two for I_pump
                beta_average = (beta_crystal(icrys)+beta_crystal(icrys+1))/2
                pump[icrys+1] = pump(icrys) * np.exp(-(sigma_abs - beta_average*(sigma_abs+sigma_ems))*Ntot_gradient(icrys)*crystal_step)
            
        #   now make the case of Backreflecetion - rough approximation, that the
        #   beta hasn't changed during the roundtrip - valid for the pump
        #   (integration step is ~5 orders of magnitude longer than the roundtrip),
        #   but for the pulse it might get a pitty - solution: also integration
        #   during roundtrip or more slices to converge
            if mode['BRM'] == 1: 
                beta_crystal = np.flipud(beta_crystal)
                
                pump_BRM[0] = pump[-1] * mode.R
                Ntot_gradient = np.flipud(Ntot_gradient)
            
        #   this is the negative direction
                for jcrys in range(steps_crystal-1):
        #           step one is from point one to two for I_pump
                    beta_average = (beta_crystal[jcrys]+beta_crystal[jcrys+1])/2
                    pump_BRM[jcrys+1] = pump_BRM[jcrys] * np.exp(-(sigma_abs - beta_average*(sigma_abs+sigma_ems))*Ntot_gradient[jcrys]*crystal_step)

        #         now turn the second pumppart and the beta again
                pump_BRM = np.rot90(pump_BRM,2)
                beta_crystal = np.flipud(beta_crystal)
                
        #         full pump intensity is I+ + I-
                pump_l = pump +pump_BRM
                Ntot_gradient = np.flipud(Ntot_gradient)
                
            else:
                pump_l = pump
        
    #   now calculate the local beta
        for ibeta in range (steps_crystal):
            A1 = sigma_abs*pump_l[ibeta]/(h*c/wavelength)
            C1 = (sigma_abs+sigma_ems)*pump_l(ibeta)/(h*c/wavelength)+1/tau_fluo
        
            beta_crystal[ibeta] = A1/C1*(1-np.exp(-C1*time_step))+ beta_crystal[ibeta]*np.exp(-C1*time_step)   
        
    #     if icrys or jcrys makes no difference
        pulse[itime] = pump[icrys+1]
        beta_store[:,itime]=beta_crystal
    
    return([beta_crystal,beta_store,pulse,Ntot_gradient])
