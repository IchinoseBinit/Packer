

step 1: On store selection screen click start audit button -> navigate to stock_rack_scan screen

step 2: Scan rack -> if selectedStore.type is MAIN_STORE -> navigate to carton_scan_screen
                     else navigate to product_scan_screen

step 3 (MAIN_STORE): Scan carton code get carton id -> navigate to product_scan_screen

step 4: scan product code -> till you want. (if not scanned any product -> screen have "Change Rack" button)

step 5: After scanning products -> screen have "Complete Verification" button

step 6: click "Complete Verification" button -> ask for completion confirmation "no. of scanned units: X";
        if yes -> call complete verification api
        if no -> continue scanning products

step 7: After complete verification api call -> then it checks if selectedStore.type is MAIN_STORE -> navigate to carton_scan_screen (screen have "Change Rack" button)
                     else stays on product_scan_screen (screen have "Change Rack" button)



