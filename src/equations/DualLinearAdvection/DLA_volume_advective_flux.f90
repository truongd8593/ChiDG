module DLA_volume_advective_flux
#include <messenger.h>
    use mod_kinds,              only: rk,ik
    use mod_constants,          only: NFACES,ZERO,ONE,TWO,HALF, &
                                      XI_MIN,XI_MAX,ETA_MIN,ETA_MAX,ZETA_MIN,ZETA_MAX,DIAG

    use atype_volume_flux,      only: volume_flux_t
    use type_mesh,              only: mesh_t
    use type_solverdata,        only: solverdata_t
    use type_seed,              only: seed_t


    use mod_interpolate,        only: interpolate_element
    use mod_integrate,          only: integrate_volume_flux
    use mod_DNAD_tools,         only: compute_neighbor_face, compute_seed
    use DNAD_D

    use type_properties,        only: properties_t
    use DLA_properties,         only: DLA_properties_t
    implicit none

    private



    !> This equation set exists really just to test equationsets with 
    !! more than one equation. The idea is just to compute the linear
    !! advecdtion solution twice at the same time. The equations are 
    !! independent of each other. So, we can verify, for example,
    !! the volume flux jacobians for each equation. They should be the
    !! same as for the single LinearAdvection equation set
    !!
    !!
    !-------------------------------------------------------------
    type, extends(volume_flux_t), public :: DLA_volume_advective_flux_t

    contains
        procedure   :: compute

    end type DLA_volume_advective_flux_t

contains

    !===========================================================
    !
    !   Volume Flux routine for Scalar
    !
    !===========================================================
    subroutine compute(self,mesh,sdata,prop,idom,ielem,iblk)
        class(DLA_volume_advective_flux_t),     intent(in)      :: self
        type(mesh_t),                           intent(in)      :: mesh(:)
        type(solverdata_t),                     intent(inout)   :: sdata
        class(properties_t),                    intent(inout)   :: prop
        integer(ik),                            intent(in)      :: idom, ielem, iblk



        type(AD_D), allocatable :: ua(:), ub(:), flux_x(:), flux_y(:), flux_z(:)
        real(rk)                :: cx, cy, cz
        integer(ik)             :: nnodes, ierr, idonor, iface
        type(seed_t)            :: seed
        integer(ik)             :: iu_a, iu_b, i


        idonor = 0
        iface  = iblk

        associate (elem => mesh(idom)%elems(ielem), q => sdata%q)


            !
            ! Get variable index from equation set
            !
            iu_a = prop%get_eqn_index('u_a')
            iu_b = prop%get_eqn_index('u_b')


            !
            ! Get equation set properties
            !
            select type(prop)
                type is (DLA_properties_t)
                    cx = prop%c(1)
                    cy = prop%c(2)
                    cz = prop%c(3)
            end select



            !
            ! Allocate storage for variable values at quadrature points
            !
            nnodes = elem%gq%nnodes_v
            allocate(ua(nnodes),        &
                     ub(nnodes),        &
                     flux_x(nnodes),    &
                     flux_y(nnodes),    &
                     flux_z(nnodes),    stat = ierr)
            if (ierr /= 0) call AllocationError


            !
            ! Get seed element for derivatives
            !
            seed = compute_seed(mesh,idom,ielem,iface,idonor,iblk)



            !
            ! Interpolate solution to quadrature nodes
            !
            call interpolate_element(mesh,q,idom,ielem,iu_a,ua,seed)
            call interpolate_element(mesh,q,idom,ielem,iu_b,ub,seed)



            !
            ! Compute volume flux at quadrature nodes
            !
            flux_x = cx  *  ua
            flux_y = cy  *  ua
            flux_z = cz  *  ua

            call integrate_volume_flux(elem,sdata,idom,iu_a,iblk,flux_x,flux_y,flux_z)



            ! Compute volume flux at quadrature nodes
            flux_x = cx  *  ub
            flux_y = cy  *  ub
            flux_z = cz  *  ub

            call integrate_volume_flux(elem,sdata,idom,iu_b,iblk,flux_x,flux_y,flux_z)



        end associate

    end subroutine




end module DLA_volume_advective_flux
