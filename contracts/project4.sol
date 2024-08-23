// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MOOCPlatform {
    // Structure to represent a Course
    struct Course {
        uint256 id;
        string title;
        string description;
        uint256 price;
        bool isAvailable;
    }

    // Structure to represent a Student's enrollment
    struct Enrollment {
        uint256 courseId;
        address student;
        bool isEnrolled;
        uint256 score; // For grading purposes
    }

    // Structure to represent a Certification
    struct Certification {
        uint256 courseId;
        address student;
        bool isCertified;
    }

    address public owner;  // Owner of the MOOC contract
    uint256 public totalCourses;  // Total number of courses available

    // Mappings
    mapping(uint256 => Course) public courses;
    mapping(uint256 => Enrollment) public enrollments;  // CourseID to Enrollment
    mapping(address => uint256) public studentToCourse; // Student address to CourseID
    mapping(uint256 => Certification) public certifications; // CourseID to Certification

    // Events
    event CourseAdded(uint256 indexed courseId, string title, uint256 price);
    event CourseUpdated(uint256 indexed courseId, string title, string description, uint256 price);
    event CourseEnrolled(address indexed student, uint256 indexed courseId);
    event EnrollmentCanceled(address indexed student, uint256 indexed courseId);
    event CourseCompleted(address indexed student, uint256 indexed courseId, uint256 score);
    event CertificationIssued(address indexed student, uint256 indexed courseId);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // Constructor to initialize the owner
    constructor() {
        owner = msg.sender;  // MOOC owner is the deployer of the contract
    }

    // Modifier to restrict functions to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Modifier to ensure payment matches course price
    modifier correctPayment(uint256 courseId) {
        require(msg.value >= courses[courseId].price, "Insufficient Ether provided");
        _;
    }

    // Function to add a new course (only the owner can add courses)
    function addCourse(uint256 _courseId, string memory _title, string memory _description, uint256 _price) public onlyOwner {
        require(_price > 0, "Course price must be greater than 0");
        require(bytes(_title).length > 0, "Course title cannot be empty");
        require(bytes(_description).length > 0, "Course description cannot be empty");

        courses[_courseId] = Course(_courseId, _title, _description, _price, true);
        totalCourses++;
        emit CourseAdded(_courseId, _title, _price);
    }

    // Function to update an existing course (only the owner can update courses)
    function updateCourse(uint256 _courseId, string memory _title, string memory _description, uint256 _price) public onlyOwner {
        Course storage course = courses[_courseId];
        require(course.isAvailable, "Course does not exist");
        require(_price > 0, "Course price must be greater than 0");

        course.title = _title;
        course.description = _description;
        course.price = _price;
        emit CourseUpdated(_courseId, _title, _description, _price);
    }

    // Function to enroll in a course
    function enrollInCourse(uint256 _courseId) public payable correctPayment(_courseId) {
        Course memory course = courses[_courseId];
        
        // Check course availability
        require(course.isAvailable, "Course is not available");

        // Check if already enrolled
        require(enrollments[_courseId].isEnrolled == false, "Already enrolled in this course");

        // Mark course as enrolled
        enrollments[_courseId] = Enrollment(_courseId, msg.sender, true, 0);
        studentToCourse[msg.sender] = _courseId;

        emit CourseEnrolled(msg.sender, _courseId);
    }

    // Function to cancel enrollment
    function cancelEnrollment() public {
        uint256 courseId = studentToCourse[msg.sender];
        Enrollment storage enrollment = enrollments[courseId];

        require(enrollment.isEnrolled, "No enrollment found for this address");
        require(enrollment.student == msg.sender, "You are not enrolled in this course");

        // Mark enrollment as canceled
        enrollment.isEnrolled = false;
        studentToCourse[msg.sender] = 0;

        // Refund Ether (could be modified for partial refunds)
        uint256 refundAmount = courses[courseId].price;
        payable(msg.sender).transfer(refundAmount);

        emit EnrollmentCanceled(msg.sender, courseId);
    }

    // Function to complete a course
    function completeCourse(uint256 _courseId, uint256 _score) public {
        Enrollment storage enrollment = enrollments[_courseId];

        require(enrollment.isEnrolled, "No enrollment found for this course");
        require(enrollment.student == msg.sender, "You are not enrolled in this course");

        // Mark course as completed and issue certification
        certifications[_courseId] = Certification(_courseId, msg.sender, true);
        enrollment.isEnrolled = false;
        enrollment.score = _score;

        emit CourseCompleted(msg.sender, _courseId, _score);
        emit CertificationIssued(msg.sender, _courseId);
    }

    // Function for the owner to withdraw all funds
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(owner).transfer(balance);

        emit FundsWithdrawn(owner, balance);
    }

    // Function to check course availability
    function isCourseAvailable(uint256 _courseId) public view returns (bool) {
        return courses[_courseId].isAvailable;
    }

    // Function to get course details
    function getCourse(uint256 _courseId) public view returns (Course memory) {
        require(courses[_courseId].isAvailable, "Course does not exist");
        return courses[_courseId];
    }

    // Function to get course price
    function getCoursePrice(uint256 _courseId) public view returns (uint256) {
        return courses[_courseId].price;
    }

    // Function to get enrollment status
    function getEnrollmentStatus(uint256 _courseId) public view returns (bool) {
        return enrollments[_courseId].isEnrolled;
    }

    // Function to get contract balance (platform earnings)
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

