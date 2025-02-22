from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver import ActionChains
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from time import sleep 
import sys
import re 

query = sys.argv[1]

# options and driver set up ActionBuilder
options = webdriver.FirefoxOptions()
# options.add_argument("-headless")
driver = webdriver.Firefox(options=options)
wait =  WebDriverWait(driver, timeout=10)


driver.get("https://www.perplexity.ai/")
input_element = wait.until(
    EC.presence_of_all_elements_located((By.TAG_NAME, "textarea"))
)[0]

# start close iframe logic
iframe_element = wait.until(
    EC.presence_of_all_elements_located((By.XPATH, "//iframe[@title='Sign in with Google Dialog']"))
)[0]

driver.switch_to.frame(iframe_element)
close_iframe_element = wait.until(
    EC.presence_of_all_elements_located((By.XPATH, "//div[@id='close']"))
)[0]

ActionChains(driver)\
    .move_to_element(close_iframe_element)\
    .click()\
    .pause(1)\
    .perform()

driver.switch_to.default_content()
# end close iframe logic 

ActionChains(driver)\
    .move_to_element(input_element)\
    .click()\
    .pause(1)\
    .send_keys(query)\
    .send_keys(Keys.RETURN)

stop_element = wait.until(
    EC.presence_of_all_elements_located((By.XPATH, '//div[contains(text(), "Related")]'))
)
  
container_element = driver.find_element(By.XPATH, '//div[@dir="auto"]')
words = container_element.text.split()

def remove_ending_number(word):
    w = list(word)
    if not w[-1].isalnum() and re.search("\\d", w[-2]):
        del w[-2]
    elif re.search("\\d", w[-1]):
        del w[-1]
    return "".join(w)
        
text  = " ".join(map(remove_ending_number, words))
print(text)
