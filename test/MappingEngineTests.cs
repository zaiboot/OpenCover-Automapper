namespace lib.Tests
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics.CodeAnalysis;
    using System.Reflection;
    using AutoMapper;
    using Microsoft.Extensions.Logging;
    using Microsoft.VisualStudio.TestTools.UnitTesting;
    using Moq;

    [TestClass]
    [ExcludeFromCodeCoverage]
    public class MappingEngineTests
    {
        private Mock<ILogger<MappingEngine>> _mockLogger;
        private readonly MockRepository _repository = new MockRepository(MockBehavior.Strict);

        [TestInitialize]
        public virtual void TestInitialize()
        {
            _mockLogger = _repository.Create<ILogger<MappingEngine>>();
        }

        private void AndISetupErrorLogger(Mock<ILogger<MappingEngine>> mockLogger)
        {
            AndISetUpLog(mockLogger, LogLevel.Error);
        }

        private void AndISetUpLog(Mock<ILogger<MappingEngine>> mockLogger, LogLevel logLevel)
        {
            mockLogger.Setup(l => l.Log(
                It.Is<LogLevel>(ll => ll == logLevel),
                It.IsAny<EventId>(),
                It.IsAny<object>(),
                It.IsAny<Exception>(),
                It.IsAny<Func<object, Exception, string>>()
            ));
        }

        [TestMethod]
        public void MapTesting()
        {
            var system = GivenTheSystemUnderTest();
            var classOne = new ClassOne
            {
                Id = 123
            };

            var actual = system.Map<ClassOne, ClassTwo>(classOne);
            Assert.AreEqual(actual.Id, classOne.Id, "Id is not equal");
        }


        [TestMethod]
        public void UpdateTesting()
        {
            var system = GivenTheSystemUnderTest();
            var classOne = new ClassOne
            {
                Id = 123
            };
            var classTwo = new ClassTwo
            {
                Id = 456
            };
            var actual = system.Update(classTwo, classOne);
            Assert.AreEqual(actual.Id, classTwo.Id, "Id is not equal");
            Assert.AreEqual(actual.Id, classOne.Id, "Id is not equal");
        }

        [TestMethod]
        [ExpectedException(typeof(AutoMapperMappingException))]
        public void MapTestingException()
        {
            var system = GivenTheSystemUnderTest();
            var classOne = new ClassOne
            {
                Id = 123
            };
            AndISetupErrorLogger(_mockLogger);
            system.Map<ClassOne, StringAssert>(classOne);
        }

        private IMappingEngine GivenTheSystemUnderTest()
        {
            IEnumerable<Assembly> assemblies = new[] { GetType().Assembly };
            return new MappingEngine(assemblies, _mockLogger.Object);
        }
    }
}
