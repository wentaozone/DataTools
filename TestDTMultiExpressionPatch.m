#import "SkankySDK/SkankySDK-TestCase.h"

#import "DTMultiExpressionPatch.h"


@interface TestDTMultiExpressionPatch : SkankySDK_TestCase
@end

@implementation TestDTMultiExpressionPatch

- (void)testExpressions
{
	DTMultiExpressionPatch *p = [[DTMultiExpressionPatch alloc] initWithIdentifier:nil];
	GHAssertNotNil(p,@"");

	GHAssertEquals([[p inputPorts] count],(NSUInteger)1,@"should start with 1 input port");
	GHAssertEqualStrings([[[p inputPorts] objectAtIndex:0] key],@"t",@"should start with 1 input port: t");

	GHAssertEquals([[p outputPorts] count],(NSUInteger)3,@"should start with 3 output ports");
	GHAssertEqualStrings([[[p outputPorts] objectAtIndex:0] key],@"outputStructure",@"should start with output structure port");
	GHAssertEqualStrings([[[p outputPorts] objectAtIndex:1] key],@"x",@"should start with output port x");
	GHAssertEqualStrings([[[p outputPorts] objectAtIndex:2] key],@"y",@"should start with output port y");

	[self setInputValue:[NSNumber numberWithDouble:0] forPort:@"t" onPatch:p];
	[self executePatch:p];
	GHAssertEqualsWithAccuracy([[self getOutputForPort:@"x" onPatch:p] doubleValue],1.,0.00001,@"cos(0) should = 1");
	GHAssertEqualsWithAccuracy([[self getOutputForPort:@"y" onPatch:p] doubleValue],0.,0.00001,@"sin(0) should = 0");

	[self setInputValue:[NSNumber numberWithDouble:90] forPort:@"t" onPatch:p];
	[self executePatch:p];
	GHAssertEqualsWithAccuracy([[self getOutputForPort:@"x" onPatch:p] doubleValue],0.,0.00001,@"cos(90) should = 0");
	GHAssertEqualsWithAccuracy([[self getOutputForPort:@"y" onPatch:p] doubleValue],1.,0.00001,@"sin(90) should = 1");

	// errors generated by our expression-line parser
	{
		NSDictionary *error;

		[p setSource:@"x = cos(t)" ofType:@"expression"];
		error = [p compileSourceOfType:@"expression"];
		GHAssertEquals([error count],(NSUInteger)0,@"an expression with spaces should compile without error");

		[p setSource:@"yay" ofType:@"expression"];
		error = [p compileSourceOfType:@"expression"];
		GHAssertEquals([error count],(NSUInteger)3,@"should have an error dictionary with 3 elements");
		GHAssertEqualStrings([error objectForKey:@"message"],@"No '=' found in expression.",@"expression without = should generate error");

		[p setSource:@"=yay" ofType:@"expression"];
		error = [p compileSourceOfType:@"expression"];
		GHAssertEquals([error count],(NSUInteger)3,@"should have an error dictionary with 3 elements");
		GHAssertEqualStrings([error objectForKey:@"message"],@"No variable name for assignment.",@"expression without a variable for assignment should generate error");

		[p setSource:@"a=b\na=c" ofType:@"expression"];
		error = [p compileSourceOfType:@"expression"];
		GHAssertEquals([error count],(NSUInteger)3,@"should have an error dictionary with 3 elements");
		GHAssertEqualStrings([error objectForKey:@"message"],@"Variable a was already declared.",@"expression redefining a result should generate error");

		[p setSource:@"a=b\nb=1" ofType:@"expression"];
		error = [p compileSourceOfType:@"expression"];
		GHAssertEquals([error count],(NSUInteger)3,@"should have an error dictionary with 3 elements");
		GHAssertEqualStrings([error objectForKey:@"message"],@"The same variable name can't be used as both an input and an output.",@"expression redefining a parameter should generate error");

		@try
		{
			[p setSource:@"!=4" ofType:@"expression"];
			error = [p compileSourceOfType:@"expression"];
			GHAssertEquals([error count],(NSUInteger)3,@"should have an error dictionary with 3 elements");
			GHAssertEqualStrings([error objectForKey:@"message"],@"Please use alphanumeric variable names.",@"expression defining a non-alphanumeric variable should generate error (otherwise QCMathematicalExpression flips out)");
		}
		@catch (NSException *e)
		{
			GHFail(@"expression defining a non-alphanumeric variable should generate error (otherwise QCMathematicalExpression flips out)");
		}
	}

	// errors generated by QCMathematicalExpression
	{
		NSDictionary *error;

		[p setSource:@"a=" ofType:@"expression"];
		error = [p compileSourceOfType:@"expression"];
		GHAssertEquals([error count],(NSUInteger)3,@"should have an error dictionary with 3 elements");
		GHAssertEqualStrings([error objectForKey:@"message"],@"Syntax Error: Empty Expression",@"variable without an expression should generate error");
	}

	[p setSource:@"a=1\n\nb=2" ofType:@"expression"];
	GHAssertEquals([[p compileSourceOfType:@"expression"] count],(NSUInteger)0,@"expression containing back-to-back newlines should compile without errors");

	[p setSource:@"a=1\nb=a" ofType:@"expression"];
	GHAssertEquals([[p compileSourceOfType:@"expression"] count],(NSUInteger)0,@"expression defining an output variable, with subsequent expression referencing that output variable, should compile without errors");


	[p release];
}

@end