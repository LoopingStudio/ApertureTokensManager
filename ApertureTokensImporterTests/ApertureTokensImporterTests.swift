import Foundation
import Testing

@Suite("Parsing Tests")
struct ApertureTokensImporterTests {
  @Test("Test New JSON Structure Parsing")
  func testNewJSONStructureParsing() {
    let sampleJSON = """
        {
          "metadata": {
            "exportedAt": "2026-02-04T11:52:41.422Z",
            "timestamp": 1770205961422,
            "version": "1.0.0",
            "generator": "Aperture Exporter"
          },
          "tokens": [
            {
              "name": "bg-error-solid",
              "type": "token",
              "path": "Colors/Background/bg-error-solid",
              "modes": {
                "Legacy": {
                  "light": {
                    "hex": "#DC2626",
                    "primitiveName": "UI Colors/Red/600"
                  },
                  "dark": {
                    "hex": "#DC2626", 
                    "primitiveName": "UI Colors/Red/600"
                  }
                },
                "New Brand": {
                  "light": {
                    "hex": "#EF4444",
                    "primitiveName": "UI Colors/Red/500"
                  },
                  "dark": {
                    "hex": "#EF4444",
                    "primitiveName": "UI Colors/Red/500"
                  }
                }
              }
            }
          ]
        }
        """.data(using: .utf8)!

    do {
      let tokenExport = try JSONDecoder().decode(TokenExport.self, from: sampleJSON)

      // Vérifier les métadonnées
      assert(tokenExport.metadata.version == "1.0.0")
      assert(tokenExport.metadata.generator == "Aperture Exporter")

      // Vérifier le token
      let token = tokenExport.tokens.first!
      assert(token.name == "bg-error-solid")
      assert(token.type == .token)
      assert(token.path == "Colors/Background/bg-error-solid")

      // Vérifier les modes
      let modes = token.modes!
      let legacy = modes.legacy!
      let newBrand = modes.newBrand!

      // Vérifier Legacy
      assert(legacy.light?.hex == "#DC2626")
      assert(legacy.light?.primitiveName == "UI Colors/Red/600")
      assert(legacy.dark?.hex == "#DC2626")
      assert(legacy.dark?.primitiveName == "UI Colors/Red/600")

      // Vérifier New Brand
      assert(newBrand.light?.hex == "#EF4444")
      assert(newBrand.light?.primitiveName == "UI Colors/Red/500")
      assert(newBrand.dark?.hex == "#EF4444")
      assert(newBrand.dark?.primitiveName == "UI Colors/Red/500")

      print("✅ Test de parsing réussi - La nouvelle structure JSON est correctement supportée!")

    } catch {
      print("❌ Erreur de parsing: \\(error)")
    }
  }
}
