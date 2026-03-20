import os
import time
from datetime import datetime
from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from selenium.webdriver.common.by import By


class ScreenshotHelper:
    """Robot Framework library for capturing before/during/after screenshots per step."""

    ROBOT_LIBRARY_SCOPE = 'SUITE'

    HIGHLIGHT_STYLE = (
        "outline: 3px solid red !important; "
        "outline-offset: 2px !important; "
        "box-shadow: 0 0 10px 2px rgba(255,0,0,0.5) !important;"
    )

    def __init__(self):
        self._screenshot_dir = None

    def _get_sl(self):
        return BuiltIn().get_library_instance('SeleniumLibrary')

    def _get_driver(self):
        return self._get_sl().driver

    def set_screenshot_directory(self, path):
        """Sets the directory where screenshots will be saved."""
        self._screenshot_dir = os.path.abspath(path)
        os.makedirs(self._screenshot_dir, exist_ok=True)
        logger.info(f"Screenshot directory set to: {self._screenshot_dir}")

    def _screenshot_path(self, step_number, phase):
        if not self._screenshot_dir:
            raise RuntimeError("Screenshot directory not set. Call Set Screenshot Directory first.")
        filename = f"step_{step_number}_{phase}.png"
        return os.path.join(self._screenshot_dir, filename)

    def capture_before_screenshot(self, step_number):
        """Captures a screenshot of the page BEFORE any action is taken."""
        path = self._screenshot_path(step_number, "before")
        driver = self._get_driver()
        driver.save_screenshot(path)
        logger.info(f"Step {step_number}: Before screenshot saved to {path}")
        return path

    def capture_during_screenshot(self, step_number, xpath):
        """Highlights the target element and captures a screenshot.
        If the xpath is empty or element is not found, captures page as-is."""
        path = self._screenshot_path(step_number, "during")
        driver = self._get_driver()

        if not xpath or xpath.strip() == '':
            driver.save_screenshot(path)
            logger.info(f"Step {step_number}: During screenshot (no element) saved to {path}")
            return path

        try:
            element = driver.find_element(By.XPATH, xpath)
            # Save original style
            original_style = element.get_attribute("style") or ""
            # Apply highlight
            driver.execute_script(
                "arguments[0].setAttribute('style', arguments[1]);",
                element, original_style + self.HIGHLIGHT_STYLE
            )
            # Scroll element into view
            driver.execute_script(
                "arguments[0].scrollIntoView({block: 'center', behavior: 'instant'});",
                element
            )
            time.sleep(0.2)
            driver.save_screenshot(path)
            # Restore original style
            driver.execute_script(
                "arguments[0].setAttribute('style', arguments[1]);",
                element, original_style
            )
            logger.info(f"Step {step_number}: During screenshot (highlighted) saved to {path}")
        except Exception as e:
            logger.warn(f"Step {step_number}: Could not highlight element '{xpath}': {e}. Taking plain screenshot.")
            driver.save_screenshot(path)

        return path

    def capture_after_screenshot(self, step_number):
        """Captures a screenshot of the page AFTER the action is completed."""
        path = self._screenshot_path(step_number, "after")
        driver = self._get_driver()
        driver.save_screenshot(path)
        logger.info(f"Step {step_number}: After screenshot saved to {path}")
        return path
