#pragma once

#ifndef PIMPL_H_TV7E3C9K
#define PIMPL_H_TV7E3C9K

/*
 * + 声明结构体 和结构体指针
 * */
//! \brief Declares a pimpl pointer.
#define RPCLIB_DECLARE_PIMPL()                                                \
    struct impl; std::unique_ptr<impl> pimpl;

#endif /* end of include guard: PIMPL_H_TV7E3C9K */
