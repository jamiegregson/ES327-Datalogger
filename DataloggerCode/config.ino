  ////////////////
  /// CONFIG MODE
  ////////////////
void config() {
  // GET CURRENT TIME
  unsigned long startTime = millis();
  // SET LED FLASH TIME
  unsigned long duration = 10000;
  while (millis() - startTime <= duration) {
    // FLASH LEDS
    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(LED_BUILTIN, HIGH);
    delay(100);
    digitalWrite(LED_BUILTIN, LOW);
    delay(100);
  }

  // INITIALISE LIBRARIES AND DEFINITIONS
  #include <FlashAsEEPROM.h>
  #include "bsec.h"
  Bsec gassensor;
  String output;

  // START STATE UPDATE COUNTER
  int stateUpdateCounter == 0

  // SET SAVE STATE PERIOD 
  #define STATE_SAVE_PERIOD	UINT32_C(7 * 60 * 1000) // 7 minutes

  
  Serial.begin(9600);
  Wire.begin();

  gassensor.begin(BME680_I2C_ADDR_SECONDARY, Wire);
  loadState();

  bsec_virtual_sensor_t sensorList[10] = {
    BSEC_OUTPUT_RAW_TEMPERATURE,
    BSEC_OUTPUT_RAW_PRESSURE,
    BSEC_OUTPUT_RAW_HUMIDITY,
    BSEC_OUTPUT_RAW_GAS,
    BSEC_OUTPUT_IAQ,
    BSEC_OUTPUT_STATIC_IAQ,
    BSEC_OUTPUT_CO2_EQUIVALENT,
    BSEC_OUTPUT_BREATH_VOC_EQUIVALENT,
    BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE,
    BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY,
  };

  gassensor.updateSubscription(sensorList, 10, BSEC_SAMPLE_RATE_LP);
  
  // PRINT HEADER
  output = "Timestamp [ms], raw temperature [°C], pressure [hPa], raw relative humidity [%], gas [Ohm], IAQ, IAQ accuracy, temperature [°C], relative humidity [%], Static IAQ, CO2 equivalent, breath VOC equivalent";
  Serial.println(output);

 // PRINT MEASUREMENTS TO SERIAL
  while(true) {
    unsigned long time_trigger = millis();
    if (gassensor.run()) { // If new data is available
      output = String(time_trigger);
      output += ", " + String(gassensor.rawTemperature);
      output += ", " + String(gassensor.pressure);
      output += ", " + String(gassensor.rawHumidity);
      output += ", " + String(gassensor.gasResistance);
      output += ", " + String(gassensor.iaq);
      output += ", " + String(gassensor.iaqAccuracy);
      output += ", " + String(gassensor.temperature);
      output += ", " + String(gassensor.humidity);
      output += ", " + String(gassensor.staticIaq);
      output += ", " + String(gassensor.co2Equivalent);
      output += ", " + String(gassensor.breathVocEquivalent);
      Serial.println(output);
      bool update = false;

    // UPDATE STATE DECISION
    if (stateUpdateCounter == 0) {
      if (gassensor.iaqAccuracy == 3) {
      update = true;
      stateUpdateCounter++;
      }
    } else {
      if ((stateUpdateCounter * STATE_SAVE_PERIOD) < millis()) {
      update = true;
      stateUpdateCounter++;
      }
    }

    // IF UPDATE = TRUE, UPDATE STATE
    if (update){
    updateState()}
    }}}


