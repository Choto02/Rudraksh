rm -rf INCA_libs/
source new_setup_sim.sh
#setenv SHM_PACKED_LIMIT 20480


# ncverilog  +nctimescale+1ns/1ps -f run_presim.f
# ncverilog   -f run_presim.f

#ncverilog  +nctimescale+1ns/1ps +define+INTC_SVA_OFF +define+INTCNOPWR +define+INTC_FUNCTIONAL +define+FUNCTIONAL +define+INTC_NO_PWR_PINS  +define+INTC_EMULATION -sv -f run_presim.f
# xmverilog  +access+r +xmtimescale+1ns/1ps +define+INTC_SVA_OFF +define+INTCNOPWR +define+INTC_FUNCTIONAL +define+FUNCTIONAL +define+INTC_NO_PWR_PINS  +define+INTC_EMULATION -sv -f run_presim.f
# xmverilog  +access+r +xmtimescale+1ns/1ps +define+SHM_PACKED_LIMIT=20480 +define+TSMC_INITIALIZE_MEM +define+TSMC_UNIT_DELAY +define+TSMC_NO_WARNING  -sv -f run_presim.f

#### WITHOUT SDF #####
#xmverilog  +access+r +xmtimescale+1ns/1ps +define+UNIT_DELAY  +define+no_warning -sv -f run_presim.f


#### WITH SDF #####
xmverilog  +access+r +xmtimescale+1ns/1ps +define+no_warning +xmmindelays +xmsdf_verbose  -sv -f run_presim.f


# //****************************************************************************** */
# //*      Macro Usage       : (+define[MACRO] for Verilog compiliers)             */
# //* +UNIT_DELAY : Enable fast function simulation.                              */
# //* +no_warning : Disable all runtime warnings message from this model.          */
# //* +TSMC_INITIALIZE_MEM : Initialize the memory data in verilog format.         */
# //* +TSMC_INITIALIZE_FAULT : Initialize the memory fault data in verilog format. */
# //* +TSMC_NO_TESTPINS_WARNING : Disable the wrong test pins connection error     */
# //*                             message if necessary.                            */
# //****************************************************************************** */
