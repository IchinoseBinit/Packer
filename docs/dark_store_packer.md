# Dark Store Packer Flow

Doc provided by QA: https://docs.google.com/document/d/1KmzGY6SG5NedOaMDS3dP3KLyqgHcBMY59H6zU_7m_Sk/edit?usp=sharing

## Normal Order Flow

```mermaid
flowchart TD
A[Packer Logs In] --> B[Homepage: Dashboard &<br>Online/Offline Switch]
B --> C{Packer Available &<br>New Order?}

    C -->|Notification Received| D[Packer Accepts Order]
    C -->|Sees Order in List| E[Taps 'Detail' Button]
    E --> D

    D --> F[Navigate to Basket Scanner]
    F --> G[Scan Basket Barcode/QR]
    G --> H[Navigate to Order Details<br>Product List Shown]

    H --> I[Taps a Product Card]
    I --> J[Navigate to Product Scanner]
    J --> K[Scan Product QR Code]
    K --> H

    H --> L{All Products Scanned?}
    L -->|No| I
    L -->|Yes| M['Bill This Order' Button Appears]
    M --> N[Taps 'Bill This Order']
    N --> O[Order Sent to Biller &<br>Removed from Packer's List]
    O --> B
```

## Inventory Items

```mermaid
flowchart TD
    A[Packer on Profile Page] --> B[Clicks “Inventory Items”]
    B --> C{Has Store Manager<br>Completed Receive Procedure?}

    C -->|No| D[No Transfer List Visible]
    C -->|Yes| E[Displays List of Transfer Requests<br>from Mother Warehouse]

    E --> F[Packer Identifies Request<br>& Clicks 'Details']
    F --> G[Basket Scanner Opens]
    G --> H[Scan Transfer Basket]
    H --> I[Display Product List<br>for Rack Arrangement]

    I --> J[Click on a Product]
    J --> K[Rack Scanner Opens<br>with Target Rack ID]
    K --> L[Scan Target Rack]
    L --> M[Product Scanner Opens]
    M --> N[Scan Product QR Code]
    N --> O[Product Transfer Complete!]
    O --> I

    I --> P{All Products Processed?}
    P -->|No| J
    P -->|Yes| Q[Transfer Flow Completed]
```

## Order Return

```mermaid
flowchart TD
    A[Packer on Profile Page] --> B[Clicks “Order Return”]
    B --> C{Has Dark Store Staff<br>Completed Return Procedure?}

    C -->|No| D[No Return List Visible]
    C -->|Yes| E[Displays List of Order Return Requests]

    E --> F[Packer Identifies Order<br>& Clicks 'Scan Basket']
    F --> G[Basket Scanner Opens]
    G --> H[Scan Return Basket]
    H --> I[Rack Scanner Opens<br>with Target Rack ID]

    I --> J[Scan Target Rack]
    J --> K[Product Scanner Opens]
    K --> L[Scan Product QR Code]
    L --> M[Order Return Process Complete!]
```

## Request QR

```mermaid
flowchart TD
    Start[Packer on Profile Page] --> Request[Clicks Request QR<br>for Damaged Products]

    Request --> Method{Select QR Request Method}

    Method --> WithQR
    Method --> WithoutQR
    Method --> WithRack

    subgraph WithQR[With QR Method]
        direction TB
        WQ1[Product Scanner Opens]
        WQ2[Scan Damaged Product QR]
        WQ3[Submit Request]
        WQ1 --> WQ2 --> WQ3
    end

    subgraph WithoutQR[Without QR Method]
        direction TB
        WOQ1[Product Scanner Opens]
        WOQ2[Scan All NON-Damaged Units<br>of Same Product]
        WOQ3[Click Confirm Verification]
        WOQ4[System Detects Remaining Unit<br>as Damaged]
        WOQ5[Submit Request]
        WOQ1 --> WOQ2 --> WOQ3 --> WOQ4 --> WOQ5
    end

    subgraph WithRack[With Rack Method]
        direction TB
        WR1[Rack Scanner Opens]
        WR2[Scan Rack Location]
        WR3[Display Product List<br>Name, ID, Quantity]
        WR4[Select Damaged Product]
        WR5[Camera Opens -<br>Take Photos of Damage]
        WR6[Enter Product ID]
        WR7[Submit Request]
        WR1 --> WR2 --> WR3 --> WR4 --> WR5 --> WR6 --> WR7
    end

    WithQR --> Complete[Marked as Damaged]
    WithoutQR --> Complete
    WithRack --> Complete

    Complete --> Portal[Reflects in Web Portal:<br>• Product-Damaged<br>• Returned Units-Damaged QR]

    Portal --> End[Process Complete]
```
