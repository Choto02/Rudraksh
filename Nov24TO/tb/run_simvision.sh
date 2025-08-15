rm -rf INCA_libs/
source setup_sim
ncverilog  +nctimescale+1ns/10ps +define+INTC_SVA_OFF +define+INTCNOPWR +define+INTC_FUNCTIONAL +define+FUNCTIONAL +define+INTC_NO_PWR_PINS  +define+INTC_EMULATION -sv -f run_presim.f

# ncverilog  +nctimescale+1ns/10ps +define+INTC_SVA_OFF +define+INTCNOPWR +define+INTC_FUNCTIONAL +define+FUNCTIONAL +define+no_unit_delay +define+INTC_NO_PWR_PINS  +define+INTC_EMULATION -sv -f run_presim.f

# ncverilog  +nctimescale+1ns/10ps +define+INTC_SVA_OFF +define+INTCNOPWR +define+INTC_FUNCTIONAL +define+INTC_NO_PWR_PINS  +define+INTC_EMULATION -sv -f run_presim.f
# ncverilog -ALLOWREDEFINITION +nctimescale+1ns/10ps +define+INTC_SVA_OFF +define+INTCNOPWR +define+INTC_FUNCTIONAL +define+INTC_NO_PWR_PINS  +define+INTC_EMULATION -sv -f run_presim.f
