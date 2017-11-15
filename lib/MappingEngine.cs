namespace lib
{
    using System;
    using System.Collections.Generic;
    using System.Reflection;
    using AutoMapper;
    using Microsoft.Extensions.Logging;

    /// <summary>
    /// This implementation uses automapper. Some information to check on it, please look at:
    /// https://cpratt.co/using-automapper-mapping-instances/
    /// </summary>
    public class MappingEngine : IMappingEngine
    {
        private readonly ILogger<MappingEngine> _logger;
        private readonly IMapper _mapper;

        public MappingEngine(IEnumerable<Assembly> assembliesToScan, ILogger<MappingEngine> logger )
        {
            _logger = logger;
            var config = new MapperConfiguration(cfg =>
            {
                cfg.AddProfiles(assembliesToScan);
            });
            config.AssertConfigurationIsValid();
            _mapper = config.CreateMapper();
        }

        public TDestiny Map<TSource, TDestiny>(TSource source)
        {
            try
            {
                var result =  _mapper.Map<TDestiny>(source);
                return result;
            }
            catch (AutoMapperMappingException ex)
            {
                _logger.LogError("Cannot map {0} to {1}. Error: {2}", typeof(TSource), typeof(TDestiny), ex.Message);
                throw;
            }
        }

        /// <summary>
        /// This will update <param name="source"></param> with the values from <param name="copyFrom"></param>
        /// Note: Remember to ignore collection properties if necessary.
        /// </summary>
        /// <typeparam name="TSource"></typeparam>
        /// <typeparam name="TCopyFrom"></typeparam>
        /// <param name="source"></param>
        /// <param name="copyFrom"></param>
        /// <returns></returns>
        /// <remarks>
        /// For properties of type collection:
        /// <code>
        /// AutoMapper is actually mapping the collection, not the objects in that collection, individually.
        /// </code>
        /// We will need to ignore the properties and map them manually with a loop.
        /// </remarks>
        public TSource Update<TSource, TCopyFrom>(TSource source, TCopyFrom copyFrom)
        {
            try
            {
                return _mapper.Map(copyFrom, source);
            }
            catch (AutoMapperMappingException ex)
            {
                _logger.LogError("Cannot update {0} with value from {1}. Error: {2}", typeof(TSource), typeof(TCopyFrom), ex.Message);
                throw;
            }
        }
    }
}