from typing import Optional

import requests
import statistics
from collections import deque
from time import sleep
from threading import Thread, Event

API_URL = "https://api.coindesk.com/v1/bpi/currentprice.json"


HTML_STR = """
   <html xmlns="http://www.w3.org/1999/xhtml">
   <head>
   <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
   <title>Bitcoin Status</title>
   </head>
   <body>
   <table border="1" cellpadding="15"  cellspacing="0" align="center" width="30%">
   <caption><h1>Bitcoin Status</h1></caption>
   <br/>
   <tr style="color:#06F">
   <th> Current Bitcoin Price </th>
   <th>Avg. over 10m</th>
   </tr>
   <tr>
   <td>{bitcoin_price}</td>
   <td>{btc_average}</td>
   </tr> </table>
   </body>
   </html>
   """

# Render HTML file with BTC values
def html(btc_price: float, btc_avg: float) -> None:
    with open("/tmp/index.html", "w") as f:
        f.write(HTML_STR.format(bitcoin_price=btc_price, btc_average=btc_avg))

# Get the current BTC price
def get_current_bc_price() -> float:
    response = requests.get("https://api.coindesk.com/v1/bpi/currentprice.json")
    data = response.json()
    price: str = data["bpi"]["USD"]["rate"]
    return float(price.replace(",", ""))


def update_buffer_periodically(buffer: deque, interval: int, stop_event: Event) -> None:
    while not stop_event.is_set():
        price = get_current_bc_price()
        buffer.append(price)
        sleep(interval)

# Calc BTC mean price
def btc_mean_price(buffer: deque) -> Optional[float]:
    if len(buffer) != buffer.maxlen:
        return None

    return statistics.mean(buffer)


def get_current_btc_price(buffer: deque) -> Optional[float]:
    if not len(buffer):
        return None

    return buffer[-1]


def main() -> None:
    sampling_interval = 1
    max_mean_window_size = 600
    buffer_size = max_mean_window_size // sampling_interval
    buffer = deque(maxlen=buffer_size)
    stop_event = Event()
    stop_event.clear()
    updater_thread = Thread(
        target=update_buffer_periodically,
       #daemon=True
        kwargs={
            "buffer": buffer,
            "interval": sampling_interval,
            "stop_event": stop_event,
        },
    )
    updater_thread.start()
    try:
        while True:
            if not updater_thread.is_alive():
                raise RuntimeError("The updater thread stopped running")
            btc_mean = btc_mean_price(buffer)
            current_price = get_current_btc_price(buffer)
            print(f"current price: {current_price}")
            print(f"mean: {btc_mean}")
            print(buffer)
            html(current_price, btc_mean)
            sleep(sampling_interval)
    finally:
        stop_event.set()


if __name__ == "__main__":
    main()
