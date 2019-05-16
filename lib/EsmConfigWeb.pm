use strict;
use warnings;

package EsmConfigWeb;

our $API_INDEX = ( `/bin/hostname -s` =~ /^pt-/ ) ? 0 : 1 ; # 0:DEV, 1:REL

#----------------------------
# Directory
#----------------------------
our $ROOT_DIR     = '/usr/amoeba';
our $TMP_DIR      = "/tmp";
our $APP_ROOT_DIR = "$ROOT_DIR/pub/b/ESM";
our $BIN_DIR      = "$APP_ROOT_DIR/bin";
our $DATA_DIR     = "$APP_ROOT_DIR/data";
our $LIB_DIR      = "$APP_ROOT_DIR/lib";
our $LOG_DIR      = "$APP_ROOT_DIR/log";
our $CACHE_DIR    = "$APP_ROOT_DIR/cache";
##### PBM-205 start #####
our $SPOOL_DIR    = "$APP_ROOT_DIR/spool";
##### PBM-205 end #####
our $ESM_TMP_DIR  = "$APP_ROOT_DIR/tmp";
our $ESM_TBL_DIR  = "$APP_ROOT_DIR/tbl";
our $COMMON_DATA_DIR   = "$APP_ROOT_DIR/data/common_data";
our $CUSTOMER_DATA_DIR = "$APP_ROOT_DIR/data/customer_data";
our $POSITION_DATA_DIR = "$APP_ROOT_DIR/data/position_data";
our $VOYAGE_DATA_DIR   = "$DATA_DIR/voyage";
our $DAILY_DATA_DIR    = "$DATA_DIR/esm3_daily";
our $DGC_DATA_DIR      = "$DATA_DIR/dgc";
our $AIS_DATA_DIR      = "$DATA_DIR/AIS";
our $PPS_DATA_DIR      = "$DATA_DIR/PPS";
our $DGC_EVIDENCE_DIR  = "$DATA_DIR/evidence";
##### PBM-205 start #####
our $DGC_EDIT_DELETE_EVAC_DIR      = "$SPOOL_DIR/dgc_edit_delete_evacuation";
our $DGC_EDIT_DELETE_EVAC_PROC_DIR = "$DGC_EDIT_DELETE_EVAC_DIR/process_spool";


##### PBM-205 end #####
##### v3 start #####
our $ESM3_VOYAGE_DATA_DIR = "$DATA_DIR/esm3_voyage";
our $ESM3_ANNUAL_DATA_DIR = "$DATA_DIR/annual";
##### v3 end #######

#----------------------------
# Auth
#----------------------------
our $COOKIE_EXPIRE_HOUR = 24 * 90;

#----------------------------
# Structure
#----------------------------
our $FORM_STRUCTURE_DATA = "$COMMON_DATA_DIR/form_structure_data/eu_mrv/v001.json";

#----------------------------
# publish data save directory
#----------------------------
our $PUBLISH_DATA_SAVE_DIR = "/mnt/ESM/data/customer_data";

#-----------------------------------
# Report Type
#-----------------------------------
our $DEPARTURE_REPORT  = 'DEP';
our $NOON_REPORT       = 'NOON';
our $ARRIVAL_REPORT    = 'ARR';
our $STATUS_REPORT     = "STATUS";

#-----------------------------------
# Report Type Repo
#-----------------------------------
##### BUG-039 start #####
## DEP->NOON->ARR (General Reports)
our $DEPARTURE_REPORT_REPO            = 'DEPARTURE REPORT';
our $NOON_REPORT_REPO                 = 'NOON REPORT';
our $ARRIVAL_REPORT_REPO              = 'ARRIVAL REPORT';

## In-port Noon
our $IN_PORT_NOON_REPORT              = 'IN-PORT NOON';

## EOSP
our $EOSP_REPORT                      = 'EOSP';

## ARR/FWE
our $ARRIVAL_FWE_REPORT               = 'ARR/FWE';

## BERTH (point only)
our $BERTHING                         = "BERTH";
our $BERTHING_REPORT_REPO             = "BERTHING REPORT";

## ANCHOR (start -> end)
our $ANCHORING                        = "ANCHR";
our $ANCHORING_START                  = "ANCHR START";
our $ANCHORING_START_REPORT_TYPE_ID   = "018";

our $ANCHORING_END                    = "ANCHR END";
our $ANCHORING_END_REPORT_REPO        = "ANCHORING END REPORT";

## DRIFT  (start -> end)
our $DRIFTING                         = "DRIFT";
our $DRIFTING_START                   = "DRIFT START";
our $DRIFTING_START_REPORT_TYPE_ID    = "020";

our $DRIFTING_END_REPORT_REPO         = "DRIFTING END REPORT";
our $DRIFTING_END                     = "DRIFT END";

## BUNKERING ( Overwrapped REPO -> start -> end )
our $BUNKERING                        = "BNKRG";
our $BUNKERING_REPORT_REPO            = "BUNKERING REPORT";
our $BUNKERING_START                  = "BNKRG START";
our $BUNKERING_START_REPORT_TYPE_ID   = "022";

our $BUNKERING_END                    = "BNKRG END";

## ICE PASSAGE ( Overwrapped REPO -> start -> end )
our $ICE_PASSAGE_REPORT_REPO          = "ICE PASSAGE REPORT";

our $ICE_PASSAGE_START                = "ICE START";
our $ICE_PASSAGE_START_REPORT_TYPE_ID = "025";

our $ICE_PASSAGE_END                  = "ICE END";

## CARGO (point only)
our $CARGO_INFORMATION_REPORT_REPO    = "CARGO INFORMATION REPORT";
our $CARGO_INFORMATION                = "CARGO";

## Additional ANCHOR/DRIFTs and summarize table for them
## (Change triggered on Octover 2017 'report name change' issue )
our $ANCHORING_REPORT_REPO                  = 'ANCHORING REPORT';
our $ANCHORING_REPORT_REPORT_TYPE_ID        = '007';
our $COMPLETE_ANCHORING_REPORT_REPO         = 'COMPLETE ANCHORING REPORT';
our $COMPLETE_ANCHORING_REPORT_TYPE_ID      = '027';
our $ANCHORING_START_AND_END_REPORT_REPO    = 'ANCHORING START AND END REPORT';
our $ANCHORING_START_AND_END_REPORT_TYPE_ID = '028';
our $DRIFTING_REPORT_REPO                   = 'DRIFTING REPORT';
our $DRIFTING_REPORT_TYPE_ID                = '009';
our $COMPLETE_DRIFTING_REPORT_REPO          = 'COMPLETE DRIFTING REPORT';
our $COMPLETE_DRIFTING_REPORT_TYPE_ID       = '029';
our $DRIFTING_START_AND_END_REPORT_REPO     = 'DRIFTING START AND END REPORT';
our $DRIFTING_START_AND_END_REPORT_TYPE_ID  = '030';
our $DRIFTING_REPORT_COMPLETION_REPO        = 'DRIFTING REPORT COMPLETION';
our $DRIFTING_REPORT_COMPLETION_TYPE_ID     = '031';

our %ANCHORING_END_REPORT_REPO_TABLE = (
  $ANCHORING_REPORT_REPO                => 1,
  $ANCHORING_END_REPORT_REPO            => 1,
  $COMPLETE_ANCHORING_REPORT_REPO       => 1,
  $ANCHORING_START_AND_END_REPORT_REPO  => 1
    );

our %DRIFTING_END_REPORT_REPO_TABLE = (
  $DRIFTING_REPORT_REPO               => 1,
  $DRIFTING_END_REPORT_REPO           => 1,
  $COMPLETE_DRIFTING_REPORT_REPO      => 1,
  $DRIFTING_START_AND_END_REPORT_REPO => 1,
  $DRIFTING_REPORT_COMPLETION_REPO    => 1
    );
##### BUG-039 end #####

##### PBM-205 start #####
our $LOCALHOST_IP = '127.0.0.1';
##### PBM-205 end #####

1;