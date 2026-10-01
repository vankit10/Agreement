import Foundation

enum Catalog {
    static func item(_ id: String, _ label: String, _ wording: String, brands: [String] = [], quantity: String = "", dimension: String = "", unit: String = "") -> WorkItem {
        WorkItem(id: id, label: label, wording: wording, brands: brands, selectedBrands: brands, quantity: quantity, unit: unit, dimension: dimension)
    }
    static let sections: [WorkSection] = [
        WorkSection(id: "A", title: "Structure", items: [
            item("A-frame", "Approved drawing and frame structure", "As per Approved Drawings. Frame Structure, R.C.C. Slab (Slab thickness and steel as per structure drawing or as per Architect), super structure brickwork {dimension} inch.", dimension: "4.5")]),
        WorkSection(id: "B", title: "Civil work (Material)", items: [
            item("B-sand", "Coarse sand", "Coarse sand: First class."),
            item("B-cement", "Cement", "Cement: {brands}.", brands: ["Ultratech", "Prism"]),
            item("B-brick", "Brick", "Brick: 1st class."),
            item("B-steel", "Reinforcement", "Reinforcement: {brands}.", brands: ["Gallant", "RHL"])]),
        WorkSection(id: "C", title: "Plaster work", items: [
            item("C-inside", "Inside plaster", "Inside plaster on walls."),
            item("C-elevation", "Elevation plaster", "Elevation plaster on walls.")]),
        WorkSection(id: "D", title: "Internal plumbing / drainage work", items: [
            item("D-drain", "Drainage / down pipes", "Drainage/Down Pipes of PVC ({brands}) as required.", brands: ["Astrol", "Supreme"]),
            item("D-supply", "Water supply", "CPVC ({brands}) pipes for water supply as specified.", brands: ["Astrol", "Supreme"]),
            item("D-chamber", "Chambers and traps", "Inspection Chambers, Manholes and gully traps etc. as per drawing."),
            item("D-fixtures", "Fixtures", "Toilet seat fixtures and fittings of {brands} or equivalent, Economical range.", brands: ["Cera", "Parryware"]),
            item("D-wc", "WC quantity", "W.C.: {quantity}.", quantity: "1"),
            item("D-basin", "Basin quantity", "Wash basin: {quantity} without platform.", quantity: "1"),
            item("D-tap", "Tap quantity", "Tap: {quantity}; Diverter or L band.", quantity: "1")]),
        WorkSection(id: "E", title: "Internal electrical work", items: [
            item("E-conduit", "Conduit and band", "Conduct PVC pipe + Band of medium grade of ISI make {brands}.", brands: ["Polycab", "Cap"]),
            item("E-box", "Junction and fan boxes", "Junction box, Fan box: Iron, Deep box: C.I."),
            item("E-wire", "Wire brands", "Wire: {brands}.", brands: ["RR Cable", "Polycab", "Anchor"]),
            item("E-switch", "Switch brands", "Switches: {brands}.", brands: ["RR Cable", "Polycab", "Anchor"]),
            item("E-inverter", "Inverter wiring", "Inverter Wiring.")]),
        WorkSection(id: "F", title: "Flooring (Tile)", items: [
            item("F-bath", "Bathroom tiles", "Bathroom tiles: {brands} ({dimension} feet) @ ₹55 to ₹60 {unit}.", brands: ["Kajaria"], dimension: "1 × 1.6"),
            item("F-floor", "Floor tiles", "Floor tiles: {brands} ({dimension} feet) @ ₹60 to ₹65 {unit}.", brands: ["Kajaria"], dimension: "2 × 4"),
            item("F-wall", "Bathroom wall tiles", "Wall tiles in bathroom (height {dimension} feet).", dimension: "7"),
            item("F-marble", "Kitchen marble", "Kitchen marble: ₹80 to ₹100 {unit}."),
            item("F-counter", "Kitchen backsplash", "Tiles: only {dimension} feet high above the counter.", dimension: "2")]),
        WorkSection(id: "G", title: "Door and window", items: [
            item("G-outer", "Double patam", "Only outer door and windows will be of double patam."),
            item("G-flush", "Flush doors", "All doors will be of ISI marked Flush Doors."),
            item("G-waterproof", "Bathroom door", "Bathroom door will be of waterproof flush door."),
            item("G-frame", "Window frame and glass", "Window frame will be of sagwan wood with {dimension} mm glass of {brands}.", brands: ["ASI"], dimension: "4"),
            item("G-interlock", "Main door interlock", "Main door with interlock will be provided.")]),
        WorkSection(id: "H", title: "Painting (Putty)", items: [
            item("H-putty", "Interior putty", "For interior: {brands} wall putty {quantity} coats.", brands: ["Nerolac", "JK", "Bajaj"], quantity: "2"),
            item("H-pop", "POP design", "Pop design: in all room."),
            item("H-ceiling", "False ceiling", "False ceiling: only in drawing room."),
            item("H-exterior", "Exterior paint", "For Exterior: Apex ultimate of Berger paint. Colour as per Architect and Client’s Choice.")]),
        WorkSection(id: "I", title: "Chaukhat", items: [
            item("I-chaukhat", "Chaukhat material", "Chaukhat: Malasyian Sakhu."),
            item("I-frame", "Frame material", "Door Frame and window Frame: Malasyian Sakhu.")]),
        WorkSection(id: "J", title: "Iron work", items: [
            item("J-grill", "Window grills", "GRILL WORK: On windows."),
            item("J-rail", "SS railing", "Railing to be made of SS Steel."),
            item("J-stair", "Staircase", "STAIRCASE of stainless steel."),
            item("J-ots", "OTS grill", "OTS jall in MS."),
            item("J-gate", "Main gate", "Main gate (₹{quantity}).", quantity: "25000")])
    ]
    static let terms: [Clause] = [
        Clause(id: "utilities", text: "Electricity & water supply to be provided by client before commencement of work."),
        Clause(id: "outside", text: "Any extra work outside the covered area will be calculated on item rate."),
        Clause(id: "site", text: "Arrangement of water and light on the site by owner before commencement of work."),
        Clause(id: "extras", text: "Following items will be charged extra if required by client. Any extra work will charged separately and the cost of these items are not included in the covered area rates."),
        Clause(id: "stairs", text: "Staircase has double measurement area."),
        Clause(id: "tax", text: "Tax will be charged 18% extra in case of payment in account.")
    ]
    static let extras: [ExtraWork] = [
        ExtraWork(id: "texture", label: "Texture paint / wallpaper"),
        ExtraWork(id: "soil", label: "Soil"),
        ExtraWork(id: "septic", label: "Septic tank"),
        ExtraWork(id: "kitchen", label: "Modular kitchen"),
        ExtraWork(id: "lights", label: "Concealed lights, tubelights"),
        ExtraWork(id: "boundary", label: "Parapet or boundary wall", unit: "sq ft", rate: "225"),
        ExtraWork(id: "earth", label: "Earthing for electrical"),
        ExtraWork(id: "demolition", label: "Demolition", notes: "Charge as per site condition"),
        ExtraWork(id: "elevation", label: "Elevation tile")
    ]
}
