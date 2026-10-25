import asyncio
from playwright.async_api import async_playwright

async def take_screenshot():
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            executable_path=r"C:\Program Files\Google\Chrome\Application\chrome.exe",
            headless=True,
            args=["--use-gl=angle", "--use-angle=swiftshader", "--no-sandbox"]
        )
        page = await browser.new_page(viewport={"width": 1440, "height": 900})
        page.on("console", lambda msg: print(f"[CONSOLE {msg.type}] {msg.text}"))
        page.on("pageerror", lambda err: print(f"[PAGE ERROR] {err}"))
        print("Opening http://localhost:8080...")
        await page.goto("http://localhost:8080", wait_until="networkidle")
        # Wait 5 seconds for all rigged GLB models, Seated Rider Pose, and Colossal Mountain Range to render
        await asyncio.sleep(5)
        # Pitch a Mountain Campfire [G] and cast [1] Sanjeevani Bolt so screenshot_proof.png shows the Seated Rider on Mount, Campfire, and Colossal Mountain Range!
        await page.keyboard.press("g")
        await asyncio.sleep(0.5)
        await page.keyboard.press("1")
        await asyncio.sleep(0.25)
        screenshot_path = r"g:\My Drive\GitHub\RobloxGames\screenshot_proof.png"
        await page.screenshot(path=screenshot_path, full_page=False)
        print(f"Screenshot successfully captured to {screenshot_path}")

        # Capture a second screenshot at the Southern Maritime Harbor & Canal showing the Galleons, Lighthouse, Piers, Canal Bridge, Windmills & Boating!
        await page.keyboard.press("b")
        await asyncio.sleep(0.4)
        await page.click('[data-bag-act="boat"]')
        await asyncio.sleep(0.6)
        map_path = r"g:\My Drive\GitHub\RobloxGames\shop_proof.png"
        await page.screenshot(path=map_path, full_page=False)
        print(f"Harbor & Boating screenshot successfully captured to {map_path}")
        await browser.close()

if __name__ == "__main__":
    asyncio.run(take_screenshot())
