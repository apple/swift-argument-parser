import ArgumentParser

struct One: ParsableArguments {
    @Option var optionOneOne: String = ""
    @Option var optionOneTwo: String = ""
    @Option var optionOneThree: String = ""
    @Option var optionOneFour: String = ""
    @Option var optionOneFive: String = ""
    @Option var optionOneSix: String = ""
    @Option var optionOneSeven: String = ""
    @Option var optionOneEight: String = ""
    @Option var optionOneNine: String = ""
    @Option var optionOneTen: String = ""
}

struct Two: ParsableArguments {
    @Option var optionTwoOne: String = ""
    @Option var optionTwoTwo: String = ""
    @Option var optionTwoThree: String = ""
    @Option var optionTwoFour: String = ""
    @Option var optionTwoFive: String = ""
    @Option var optionTwoSix: String = ""
    @Option var optionTwoSeven: String = ""
    @Option var optionTwoEight: String = ""
    @Option var optionTwoNine: String = ""
    @Option var optionTwoTen: String = ""
}

struct Three: ParsableArguments {
    @Option var optionThreeOne: String = ""
    @Option var optionThreeTwo: String = ""
    @Option var optionThreeThree: String = ""
    @Option var optionThreeFour: String = ""
    @Option var optionThreeFive: String = ""
    @Option var optionThreeSix: String = ""
    @Option var optionThreeSeven: String = ""
    @Option var optionThreeEight: String = ""
    @Option var optionThreeNine: String = ""
    @Option var optionThreeTen: String = ""
}

struct Four: ParsableArguments {
    @Option var optionFourOne: String = ""
    @Option var optionFourTwo: String = ""
    @Option var optionFourThree: String = ""
    @Option var optionFourFour: String = ""
    @Option var optionFourFive: String = ""
    @Option var optionFourSix: String = ""
    @Option var optionFourSeven: String = ""
    @Option var optionFourEight: String = ""
    @Option var optionFourNine: String = ""
    @Option var optionFourTen: String = ""
}

struct Five: ParsableArguments {
    @Option var optionFiveOne: String = ""
    @Option var optionFiveTwo: String = ""
    @Option var optionFiveThree: String = ""
    @Option var optionFiveFour: String = ""
    @Option var optionFiveFive: String = ""
    @Option var optionFiveSix: String = ""
    @Option var optionFiveSeven: String = ""
    @Option var optionFiveEight: String = ""
    @Option var optionFiveNine: String = ""
    @Option var optionFiveTen: String = ""
}

struct Six: ParsableArguments {
    @Option var optionSixOne: String = ""
    @Option var optionSixTwo: String = ""
    @Option var optionSixThree: String = ""
    @Option var optionSixFour: String = ""
    @Option var optionSixFive: String = ""
    @Option var optionSixSix: String = ""
    @Option var optionSixSeven: String = ""
    @Option var optionSixEight: String = ""
    @Option var optionSixNine: String = ""
    @Option var optionSixTen: String = ""
}

struct Seven: ParsableArguments {
    @Option var optionSevenOne: String = ""
    @Option var optionSevenTwo: String = ""
    @Option var optionSevenThree: String = ""
    @Option var optionSevenFour: String = ""
    @Option var optionSevenFive: String = ""
    @Option var optionSevenSix: String = ""
    @Option var optionSevenSeven: String = ""
    @Option var optionSevenEight: String = ""
    @Option var optionSevenNine: String = ""
    @Option var optionSevenTen: String = ""
}

struct Eight: ParsableArguments {
    @Option var optionEightOne: String = ""
    @Option var optionEightTwo: String = ""
    @Option var optionEightThree: String = ""
    @Option var optionEightFour: String = ""
    @Option var optionEightFive: String = ""
    @Option var optionEightSix: String = ""
    @Option var optionEightSeven: String = ""
    @Option var optionEightEight: String = ""
    @Option var optionEightNine: String = ""
    @Option var optionEightTen: String = ""
}

struct Nine: ParsableArguments {
    @Option var optionNineOne: String = ""
    @Option var optionNineTwo: String = ""
    @Option var optionNineThree: String = ""
    @Option var optionNineFour: String = ""
    @Option var optionNineFive: String = ""
    @Option var optionNineSix: String = ""
    @Option var optionNineSeven: String = ""
    @Option var optionNineEight: String = ""
    @Option var optionNineNine: String = ""
    @Option var optionNineTen: String = ""
}

struct Ten: ParsableArguments {
    @Option var optionTenOne: String = ""
    @Option var optionTenTwo: String = ""
    @Option var optionTenThree: String = ""
    @Option var optionTenFour: String = ""
    @Option var optionTenFive: String = ""
    @Option var optionTenSix: String = ""
    @Option var optionTenSeven: String = ""
    @Option var optionTenEight: String = ""
    @Option var optionTenNine: String = ""
    @Option var optionTenTen: String = ""
}

struct Main: ParsableCommand {
    @OptionGroup var groupOne: One
    @OptionGroup var groupTwo: Two
    @OptionGroup var groupThree: Three
    @OptionGroup var groupFour: Four
    @OptionGroup var groupFive: Five
    @OptionGroup var groupSix: Six
    @OptionGroup var groupSeven: Seven
    @OptionGroup var groupEight: Eight
    @OptionGroup var groupNine: Nine
    @OptionGroup var groupTen: Ten

    func run() {
        dump(self)
    }
}

let argCount = Int(CommandLine.arguments.last ?? "") ?? 1
print("Parsing \(argCount) options")

let numberWords = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
var args: [String] = []
for _ in 0..<argCount {
  let option = "--option-\(numberWords.randomElement()!.lowercased())-\(numberWords.randomElement()!.lowercased())"
  args.append(option)
  args.append("akjlhsdfaslkdjf")
}

Main.main(args)

// Before
// 200: 0.04
// 400: 0.10
// 800: 0.33
// 1600: 1.82
// 3200: 15.26

// After
// 200: 0.03
// 400: 0.07
// 800: 0.10
// 1600: 0.22
// 3200: 0.60
// 6400: 1.85
