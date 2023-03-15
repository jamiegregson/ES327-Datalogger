void loadState() {
// INITIALISE LIBRARIES AND DEFINITIONS
#include <FlashAsEEPROM.h>
#include "bsec.h"
  
    if (EEPROM.read(0) == BSEC_MAX_STATE_BLOB_SIZE) {
      Serial.println("Loading state from EEPROM");
      for (uint8_t i = 0; i < BSEC_MAX_STATE_BLOB_SIZE; i++) {
        bsecState[i] = EEPROM.read(i + 1);  
      }
      gassensor.setState(bsecState);
      Serial.println("Loaded State");
    } else {}
  }