#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only --quiet"

escape_sql() {
  printf "%s" "$1" | sed "s/'/''/g"
}

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo

display_services() {
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

display_services
read SERVICE_ID_SELECTED

while ! [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]] || \
  ! $PSQL -c "SELECT 1 FROM services WHERE service_id = $SERVICE_ID_SELECTED;" | grep -q '^1$'
do
  echo
  echo "I could not find that service. What would you like today?"
  display_services
  read SERVICE_ID_SELECTED
done

SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
echo
echo "What's your phone number?"
read CUSTOMER_PHONE

ESCAPED_PHONE=$(escape_sql "$CUSTOMER_PHONE")
CUSTOMER_ID=$($PSQL -c "SELECT customer_id FROM customers WHERE phone = '$ESCAPED_PHONE';")

if [[ -z "$CUSTOMER_ID" ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  ESCAPED_NAME=$(escape_sql "$CUSTOMER_NAME")
  $PSQL -c "INSERT INTO customers(phone, name) VALUES('$ESCAPED_PHONE', '$ESCAPED_NAME');"
  CUSTOMER_ID=$($PSQL -c "SELECT customer_id FROM customers WHERE phone = '$ESCAPED_PHONE';")
else
  CUSTOMER_NAME=$($PSQL -c "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME

ESCAPED_TIME=$(escape_sql "$SERVICE_TIME")
$PSQL -c "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$ESCAPED_TIME');"

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
