# variant, to be configured on top level
GRIN_VARIANT							:= X
GRIN_VARIANT_PREFIX						:= $(GRIN_VARIANT)/
GRIN_BLD_VARIANT_PREFIX					:= $(BLD_PREFIX)$(GRIN_VARIANT_PREFIX)
GRIN_BIN_PREFIX							:= $(BIN_PREFIX)
GRIN_BLD_BIN_VARIANT_PREFIX				:= $(GRIN_BIN_PREFIX)$(GRIN_VARIANT_PREFIX)

# all variants
GRIN_VARIANTS							:= 8 9 10 11

# location of grin src
GRIN_SRC_PREFIX							:= $(TOP_PREFIX)grin/

# this file
GRIN_MKF								:= $(GRIN_SRC_PREFIX)files.mk

# main + sources + dpds, for .cag
GRIN_AGCODE_MAIN_SRC_CAG				:= $(patsubst %,$(GRIN_SRC_PREFIX)%.cag,GrinCode)
GRIN_AGCODE_DPDS_SRC_CAG				:= $(patsubst %,$(GRIN_SRC_PREFIX)%.cag,GrinCodeAbsSyn)
$(patsubst $(GRIN_SRC_PREFIX)%.cag,$(GRIN_BLD_VARIANT_PREFIX)%.hs,$(GRIN_AGCODE_MAIN_SRC_CAG)): $(patsubst $(GRIN_SRC_PREFIX)%.cag,$(GRIN_BLD_VARIANT_PREFIX)%.ag,$(GRIN_AGCODE_DPDS_SRC_CAG))

GRIN_AGCODE_PRETTY_MAIN_SRC_CAG			:= $(patsubst %,$(GRIN_SRC_PREFIX)%.cag,GrinCodePretty)
GRIN_AGCODE_PRETTY_DPDS_SRC_CAG			:= $(patsubst %,$(GRIN_SRC_PREFIX)%.cag,GrinCodeAbsSyn)
$(patsubst $(GRIN_SRC_PREFIX)%.cag,$(GRIN_BLD_VARIANT_PREFIX)%.hs,$(GRIN_AGCODE_PRETTY_MAIN_SRC_CAG)): $(patsubst $(GRIN_SRC_PREFIX)%.cag,$(GRIN_BLD_VARIANT_PREFIX)%.ag,$(GRIN_AGCODE_PRETTY_DPDS_SRC_CAG))

GRIN_AG_D_MAIN_SRC_CAG					:= $(GRIN_AGCODE_MAIN_SRC_CAG)
GRIN_AG_S_MAIN_SRC_CAG					:= $(GRIN_AGCODE_PRETTY_MAIN_SRC_CAG)
GRIN_AG_DS_MAIN_SRC_CAG					:= 									
GRIN_AG_ALL_MAIN_SRC_CAG				:= $(GRIN_AG_D_MAIN_SRC_CAG) $(GRIN_AG_S_MAIN_SRC_CAG) $(GRIN_AG_DS_MAIN_SRC_CAG)

GRIN_AG_ALL_DPDS_SRC_CAG				:= $(sort $(GRIN_AGCODE_DPDS_SRC_CAG) \
											$(GRIN_AGCODE_PRETTY_DPDS_SRC_CAG))

# all src
GRIN_ALL_SRC							:= $(GRIN_AG_ALL_MAIN_SRC_CAG) $(GRIN_AG_ALL_DPDS_SRC_CAG)

# distribution
GRIN_DIST_FILES							:= $(GRIN_ALL_SRC) $(GRIN_MKF)

# derived
GRIN_AG_D_MAIN_DRV_AG					:= $(patsubst $(GRIN_SRC_PREFIX)%.cag,$(GRIN_BLD_VARIANT_PREFIX)%.ag,$(GRIN_AG_D_MAIN_SRC_CAG))
GRIN_AG_S_MAIN_DRV_AG					:= $(patsubst $(GRIN_SRC_PREFIX)%.cag,$(GRIN_BLD_VARIANT_PREFIX)%.ag,$(GRIN_AG_S_MAIN_SRC_CAG))
GRIN_AG_DS_MAIN_DRV_AG					:= $(patsubst $(GRIN_SRC_PREFIX)%.cag,$(GRIN_BLD_VARIANT_PREFIX)%.ag,$(GRIN_AG_DS_MAIN_SRC_CAG))
GRIN_AG_ALL_MAIN_DRV_AG					:= $(GRIN_AG_D_MAIN_DRV_AG) $(GRIN_AG_S_MAIN_DRV_AG) $(GRIN_AG_DS_MAIN_DRV_AG)

GRIN_AG_D_MAIN_DRV_HS					:= $(GRIN_AG_D_MAIN_DRV_AG:.ag=.hs)
GRIN_AG_S_MAIN_DRV_HS					:= $(GRIN_AG_S_MAIN_DRV_AG:.ag=.hs)
GRIN_AG_DS_MAIN_DRV_HS					:= $(GRIN_AG_DS_MAIN_DRV_AG:.ag=.hs)
GRIN_AG_ALL_MAIN_DRV_HS					:= $(GRIN_AG_D_MAIN_DRV_HS) $(GRIN_AG_S_MAIN_DRV_HS) $(GRIN_AG_DS_MAIN_DRV_HS)

GRIN_AG_ALL_DPDS_DRV_AG					:= $(patsubst $(GRIN_SRC_PREFIX)%.cag,$(GRIN_BLD_VARIANT_PREFIX)%.ag,$(GRIN_AG_ALL_DPDS_SRC_CAG))

# rules
$(GRIN_AG_ALL_MAIN_DRV_AG) $(GRIN_AG_ALL_DPDS_DRV_AG): $(GRIN_BLD_VARIANT_PREFIX)%.ag: $(GRIN_SRC_PREFIX)%.cag $(SHUFFLE)
	mkdir -p $(@D)
	$(SHUFFLE) --gen=$(GRIN_VARIANT) --base=$(*F) --ag --order="$(EHC_SHUFFLE_ORDER)" $< | $(LHS2TEX) $(LHS2TEX_OPTS_NEWC) | $(SUBST_LINE_CMT) > $@

$(GRIN_AG_D_MAIN_DRV_HS): %.hs: %.ag
	$(AGC) -dr -P$(GRIN_BLD_VARIANT_PREFIX) $<

$(GRIN_AG_S_MAIN_DRV_HS): %.hs: %.ag
	$(AGC) -cfspr -P$(GRIN_BLD_VARIANT_PREFIX) $<

$(GRIN_AG_DS_MAIN_DRV_HS): %.hs: %.ag
	$(AGC) -dcfspr -P$(GRIN_BLD_VARIANT_PREFIX) $<

