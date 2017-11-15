namespace lib.Tests
{
    using System.Diagnostics.CodeAnalysis;
    using AutoMapper;

    [ExcludeFromCodeCoverage]
    public class TestingProfile : Profile
    {
        public TestingProfile()
        {
            CreateMap<ClassOne, ClassTwo>();
        }

    }
}