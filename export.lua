export type profiler = {
    New: (projectName:string?)->profiler,
    Start: (self:profiler,description:string?)->(),
    Stop: (self:profiler,resultDescription:string?)->(),
    Print: (self:profiler,index:number?)->string,
    PrintAll: (self:profiler)->string
}

return require(script.main)