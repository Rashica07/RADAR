import XCTest
@testable import RADAR

@MainActor
final class FeatureFlagsTests: XCTestCase {
    private struct Stub: FlagProvider {
        var result: Result<[String: Bool], Error>
        func fetch() async throws -> [String: Bool] { try result.get() }
    }

    private func makeDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("radar-tests-\(UUID().uuidString)")
    }

    private func makeFlags(_ provider: FlagProvider?, directory: URL? = nil) -> FeatureFlags {
        FeatureFlags(provider: provider, persistence: PersistenceController(directory: directory ?? makeDirectory()))
    }

    func testEveryFlagIsOffByDefault() {
        let flags = makeFlags(nil)
        for flag in FeatureFlag.allCases { XCTAssertFalse(flags.isEnabled(flag), flag.rawValue) }
        XCTAssertFalse(flags.isRemoteConfigured)
    }

    func testRemoteValueEnablesAFlag() async {
        let flags = makeFlags(Stub(result: .success([FeatureFlag.glitchAppIcon.rawValue: true])))
        await flags.refresh(force: true)
        XCTAssertTrue(flags.isEnabled(.glitchAppIcon))
        XCTAssertEqual(flags.remoteValue(.glitchAppIcon), true)
    }

    func testAFlagMissingFromTheServerStaysOff() async {
        let flags = makeFlags(Stub(result: .success(["something_else": true])))
        await flags.refresh(force: true)
        XCTAssertFalse(flags.isEnabled(.glitchAppIcon))
    }

    func testLocalOverrideBeatsTheServerAndCanBeCleared() async {
        let flags = makeFlags(Stub(result: .success([FeatureFlag.glitchAppIcon.rawValue: true])))
        await flags.refresh(force: true)
        flags.setOverride(.glitchAppIcon, false)
        XCTAssertFalse(flags.isEnabled(.glitchAppIcon))
        flags.setOverride(.glitchAppIcon, nil)
        XCTAssertTrue(flags.isEnabled(.glitchAppIcon))
    }

    func testAFailedRefreshKeepsTheLastKnownValues() async {
        struct Offline: Error {}
        let directory = makeDirectory()
        let firstRun = PersistenceController(directory: directory)
        let good = FeatureFlags(provider: Stub(result: .success([FeatureFlag.glitchAppIcon.rawValue: true])), persistence: firstRun)
        await good.refresh(force: true)
        firstRun.flush()

        let failing = FeatureFlags(provider: Stub(result: .failure(Offline())), persistence: PersistenceController(directory: directory))
        await failing.refresh(force: true)
        XCTAssertNotNil(failing.lastError)
        XCTAssertTrue(failing.isEnabled(.glitchAppIcon), "an offline refresh must not flip a flag")
    }

    func testValuesSurviveARelaunch() async {
        let directory = makeDirectory()
        let persistence = PersistenceController(directory: directory)
        let first = FeatureFlags(provider: Stub(result: .success([FeatureFlag.glitchAppIcon.rawValue: true])), persistence: persistence)
        await first.refresh(force: true)
        persistence.flush()

        let second = FeatureFlags(provider: nil, persistence: PersistenceController(directory: directory))
        XCTAssertTrue(second.isEnabled(.glitchAppIcon))
    }

    func testRefreshIsThrottledUnlessForced() async {
        let flags = makeFlags(Stub(result: .success([FeatureFlag.glitchAppIcon.rawValue: true])))
        await flags.refresh(force: true)
        let first = flags.lastRefresh
        await flags.refresh()
        XCTAssertEqual(flags.lastRefresh, first)
    }

    func testProviderIsNilWithoutConfiguration() {
        XCTAssertNil(SupabaseFlagProvider.fromBundle(Bundle(for: FeatureFlagsTests.self)))
    }
}

@MainActor
final class AppIconServiceTests: XCTestCase {
    private final class FakeApplier: AppIconApplying {
        var supportsAlternateIcons = true
        var alternateIconName: String?
        var shouldFail = false
        private(set) var calls: [String?] = []

        func setAlternateIconName(_ name: String?) async throws {
            calls.append(name)
            if shouldFail { throw CocoaError(.userCancelled) }
            alternateIconName = name
        }
    }

    private func makeFlags() -> FeatureFlags {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("radar-tests-\(UUID().uuidString)")
        return FeatureFlags(provider: nil, persistence: PersistenceController(directory: directory))
    }

    func testPickerIsHiddenWhileTheFlagIsOff() {
        let service = AppIconService(applier: FakeApplier())
        XCTAssertFalse(service.isPickerVisible(flags: makeFlags()))
        XCTAssertEqual(service.availableChoices(flags: makeFlags()), [.standard])
    }

    func testEnablingTheFlagRevealsTheGlitchIcon() {
        let flags = makeFlags()
        flags.setOverride(.glitchAppIcon, true)
        let service = AppIconService(applier: FakeApplier())
        XCTAssertTrue(service.isPickerVisible(flags: flags))
        XCTAssertEqual(service.availableChoices(flags: flags), [.standard, .glitch])
    }

    func testTheGlitchIconStaysListedWhileActiveEvenIfTheFlagTurnsOff() {
        let applier = FakeApplier()
        applier.alternateIconName = AppIconChoice.glitch.alternateName
        let service = AppIconService(applier: applier)
        let flags = makeFlags()
        XCTAssertEqual(service.current, .glitch)
        XCTAssertTrue(service.isPickerVisible(flags: flags), "nobody should be stuck on an icon with no way back")
        XCTAssertEqual(service.availableChoices(flags: flags), [.standard, .glitch])
    }

    func testSwitchingBackRemovesTheGlitchIconWhenTheFlagIsOff() async throws {
        let applier = FakeApplier()
        applier.alternateIconName = AppIconChoice.glitch.alternateName
        let service = AppIconService(applier: applier)
        try await service.select(.standard)
        XCTAssertEqual(service.current, .standard)
        XCTAssertFalse(service.isPickerVisible(flags: makeFlags()))
    }

    func testSelectingAnIconCallsSystemWithItsAssetName() async throws {
        let applier = FakeApplier()
        let service = AppIconService(applier: applier)
        try await service.select(.glitch)
        XCTAssertEqual(applier.calls, ["AppIconGlitch"])
        XCTAssertEqual(service.current, .glitch)
    }

    func testStandardIconIsSelectedWithNil() async throws {
        let applier = FakeApplier()
        applier.alternateIconName = "AppIconGlitch"
        let service = AppIconService(applier: applier)
        try await service.select(.standard)
        XCTAssertEqual(applier.calls.count, 1)
        XCTAssertNil(applier.calls[0])
    }

    func testSelectingTheActiveIconDoesNothing() async throws {
        let applier = FakeApplier()
        let service = AppIconService(applier: applier)
        try await service.select(.standard)
        XCTAssertTrue(applier.calls.isEmpty)
    }

    func testAFailedChangeLeavesTheCurrentIconAlone() async {
        let applier = FakeApplier()
        applier.shouldFail = true
        let service = AppIconService(applier: applier)
        do {
            try await service.select(.glitch)
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(service.current, .standard)
        }
    }

    func testPickerIsHiddenWhenTheDeviceCannotSwitchIcons() {
        let applier = FakeApplier()
        applier.supportsAlternateIcons = false
        let flags = makeFlags()
        flags.setOverride(.glitchAppIcon, true)
        XCTAssertFalse(AppIconService(applier: applier).isPickerVisible(flags: flags))
    }

    func testChoicesMapToTheAssetNamesShippedInTheCatalog() {
        XCTAssertNil(AppIconChoice.standard.alternateName)
        XCTAssertEqual(AppIconChoice.glitch.alternateName, "AppIconGlitch")
        XCTAssertEqual(AppIconChoice(alternateName: "Unknown"), .standard)
    }
}
