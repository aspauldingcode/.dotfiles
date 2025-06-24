// Test file for fold functionality
function outerFunction() {
  console.log("Outer function start");

  // Inner function 1
    function innerFunction1() {
        console.log("Inner function 1");
        let x = 1;
        let y = 2;
        return x + y;
    }

    // Inner function 2
    function innerFunction2() {
        console.log("Inner function 2");

        // Nested inner function
        function nestedFunction() {
            console.log("Nested function");
            let a = 10;
            let b = 20;
            let c = 30;
            return a + b + c;
        }

        return nestedFunction();
    }

    // Call the inner functions
    let result1 = innerFunction1();
    let result2 = innerFunction2();

    console.log("Results:", result1, result2);
    return result1 + result2;
}

// Another top-level function
function anotherFunction() {
    console.log("Another function");

    // Some comments that should fold
    // This is comment line 1
    // This is comment line 2
    // This is comment line 3
    // This is comment line 4

    let data = {
        prop1: "value1",
        prop2: "value2",
        prop3: {
            nested1: "nested value 1",
            nested2: "nested value 2",
        },
    };

    return data;
}

// Export the functions
module.exports = {
    outerFunction,
    anotherFunction,
};
