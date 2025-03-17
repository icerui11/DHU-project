# Issue for instantiate 3 SHyLoC

After synthesizing 3 SHyLoCs, it was found that each SHyLoC uses 43 DSPs, compared to previous synthesis where only 7 DSPs were used.

来源：

![1742229298366](images/18_Mar/1742229298366.png)

in ccsds_comp_shyloc_bip_mem or bip is same

related to Cz

in ccsds123_constants:

--! Cz = P\_MAX if reduced prediction; Cz = 3 + P\_MAX when full prediction is used.

constant Cz: integer := FULL\*3 + P\_MAX;

~~~

~~~

in ccsds123_parameter

constant PREDICTION_GEN: integer := 0;        --! Full (0) or reduced (1) prediction.

so there are 3+6 = 9， 并且每个mult 使用4个 Math module

![1742231145199](images/18_Mar/1742231145199.png)

在system_shyloc 中的参数如上所示
  --! Bit width of the local sum signed values.
  constant W_LS: integer := D_GEN + 3;
  --! Bit width of the localdiff signed values.
  constant W_LD: integer := D_GEN + 4;
  --! Bit width of the signed weights .
  constant W_WEI: integer := OMEGA_GEN + 3;