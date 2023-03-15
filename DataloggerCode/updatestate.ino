void updateState() {
  #include <FlashAsEEPROM.h>
  #include "bsec.h"
    gassensor.getState(bsecState);
    for (uint8_t i = 0; i < BSEC_MAX_STATE_BLOB_SIZE ; i++) {
      EEPROM.write(i + 1, bsecState[i]);
      Serial.println(bsecState[i], HEX);
    }
    EEPROM.write(0, BSEC_MAX_STATE_BLOB_SIZE);
    EEPROM.commit();
    Serial.println("Saved State");
  }
}
